#!/usr/bin/env python3
import argparse
import base64
import email.utils
import hashlib
import hmac
import os
import sys
import urllib.error
import urllib.parse
import urllib.request


def parse_connection_string(value: str) -> dict[str, str]:
    parts: dict[str, str] = {}
    for item in value.split(";"):
        if not item or "=" not in item:
            continue
        key, val = item.split("=", 1)
        parts[key] = val
    required = ["AccountName", "AccountKey", "BlobEndpoint"]
    missing = [key for key in required if key not in parts or not parts[key]]
    if missing:
        raise ValueError(f"Missing required connection string keys: {', '.join(missing)}")
    return parts


def canonicalized_headers(headers: dict[str, str]) -> str:
    items = []
    for key, value in headers.items():
        lower = key.lower()
        if lower.startswith("x-ms-"):
            items.append((lower, " ".join(value.strip().split())))
    items.sort()
    return "\n".join(f"{key}:{value}" for key, value in items)


def canonicalized_resource(account: str, parsed_url: urllib.parse.SplitResult) -> str:
    resource = f"/{account}{parsed_url.path}"
    query = urllib.parse.parse_qs(parsed_url.query, keep_blank_values=True)
    if query:
        for key in sorted(query):
            values = ",".join(sorted(v for v in query[key]))
            resource += f"\n{key.lower()}:{values}"
    return resource


def build_string_to_sign(method: str, account: str, parsed_url: urllib.parse.SplitResult, headers: dict[str, str]) -> str:
    standard_headers = {
        "Content-Encoding": "",
        "Content-Language": "",
        "Content-Length": "",
        "Content-MD5": "",
        "Content-Type": "",
        "Date": "",
        "If-Modified-Since": "",
        "If-Match": "",
        "If-None-Match": "",
        "If-Unmodified-Since": "",
        "Range": "",
    }
    for name in list(standard_headers):
        if name in headers:
            standard_headers[name] = headers[name]

    if standard_headers["Content-Length"] == "0":
        standard_headers["Content-Length"] = ""

    values = [
        method,
        standard_headers["Content-Encoding"],
        standard_headers["Content-Language"],
        standard_headers["Content-Length"],
        standard_headers["Content-MD5"],
        standard_headers["Content-Type"],
        standard_headers["Date"],
        standard_headers["If-Modified-Since"],
        standard_headers["If-Match"],
        standard_headers["If-None-Match"],
        standard_headers["If-Unmodified-Since"],
        standard_headers["Range"],
        canonicalized_headers(headers),
        canonicalized_resource(account, parsed_url),
    ]
    return "\n".join(values)


def signed_request(method: str, url: str, api_version: str, body: bytes | None = None, extra_headers: dict[str, str] | None = None, ok_statuses: set[int] | None = None) -> int:
    conn = parse_connection_string(os.environ["AZURITE_CONNECTION_STRING"])
    account = conn["AccountName"]
    key = base64.b64decode(conn["AccountKey"])

    headers = {
        "x-ms-date": email.utils.formatdate(usegmt=True),
        "x-ms-version": api_version,
    }
    if extra_headers:
        headers.update(extra_headers)
    if body is not None and "Content-Length" not in headers:
        headers["Content-Length"] = str(len(body))

    parsed = urllib.parse.urlsplit(url)
    string_to_sign = build_string_to_sign(method, account, parsed, headers)
    signature = base64.b64encode(hmac.new(key, string_to_sign.encode("utf-8"), hashlib.sha256).digest()).decode("ascii")
    headers["Authorization"] = f"SharedKey {account}:{signature}"

    request = urllib.request.Request(url=url, data=body, method=method, headers=headers)
    try:
        with urllib.request.urlopen(request) as response:
            status = response.status
    except urllib.error.HTTPError as exc:
        status = exc.code
        if ok_statuses and status in ok_statuses:
            return status
        detail = exc.read().decode("utf-8", errors="replace").strip()
        raise RuntimeError(f"Azurite request failed: {method} {url} returned {status}. {detail}") from exc

    if ok_statuses and status not in ok_statuses:
        raise RuntimeError(f"Azurite request failed: {method} {url} returned {status}")
    return status


def blob_url(container: str, blob: str | None = None) -> str:
    conn = parse_connection_string(os.environ["AZURITE_CONNECTION_STRING"])
    base = conn["BlobEndpoint"].rstrip("/")
    if blob is None:
        return f"{base}/{container}"
    blob_path = urllib.parse.quote(blob, safe="/")
    return f"{base}/{container}/{blob_path}"


def cmd_verify(args: argparse.Namespace) -> int:
    conn = parse_connection_string(os.environ["AZURITE_CONNECTION_STRING"])
    url = f"{conn['BlobEndpoint'].rstrip('/')}?comp=list"
    signed_request("GET", url, args.api_version, ok_statuses={200})
    return 0


def cmd_seed(args: argparse.Namespace) -> int:
    container = blob_url(args.container)
    signed_request(
        "PUT",
        f"{container}?restype=container",
        args.api_version,
        extra_headers={"Content-Length": "0"},
        ok_statuses={201, 202, 409},
    )

    with open(args.file, "rb") as handle:
        body = handle.read()

    signed_request(
        "PUT",
        blob_url(args.container, args.blob),
        args.api_version,
        body=body,
        extra_headers={
            "Content-Type": args.content_type,
            "Content-MD5": base64.b64encode(hashlib.md5(body).digest()).decode("ascii"),
            "x-ms-blob-type": "BlockBlob",
        },
        ok_statuses={201},
    )
    return 0


def cmd_cleanup(args: argparse.Namespace) -> int:
    signed_request(
        "DELETE",
        blob_url(args.container, args.blob),
        args.api_version,
        ok_statuses={202, 404},
    )
    signed_request(
        "DELETE",
        f"{blob_url(args.container)}?restype=container",
        args.api_version,
        ok_statuses={202, 404},
    )
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Azurite helper for the hybrid multi-vendor lab.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    verify = subparsers.add_parser("verify")
    verify.add_argument("--api-version", required=True)
    verify.set_defaults(func=cmd_verify)

    seed = subparsers.add_parser("seed")
    seed.add_argument("--container", required=True)
    seed.add_argument("--blob", required=True)
    seed.add_argument("--file", required=True)
    seed.add_argument("--content-type", required=True)
    seed.add_argument("--api-version", required=True)
    seed.set_defaults(func=cmd_seed)

    cleanup = subparsers.add_parser("cleanup")
    cleanup.add_argument("--container", required=True)
    cleanup.add_argument("--blob", required=True)
    cleanup.add_argument("--api-version", required=True)
    cleanup.set_defaults(func=cmd_cleanup)

    args = parser.parse_args()
    if "AZURITE_CONNECTION_STRING" not in os.environ:
        raise RuntimeError("AZURITE_CONNECTION_STRING must be set.")
    return args.func(args)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
