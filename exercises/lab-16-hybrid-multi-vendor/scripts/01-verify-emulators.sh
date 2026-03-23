#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AZURE_CONFIG_DIR="$ROOT_DIR/.azure"
AZURE_STORAGE_API_VERSION="${AZURE_STORAGE_API_VERSION:-2020-04-08}"
LOCALSTACK_HEALTH_URL="http://localhost:4566/_localstack/health"
AZURITE_BLOB_URL="http://127.0.0.1:10000/devstoreaccount1?comp=list"
AZURITE_CONNECTION_STRING="${AZURE_STORAGE_CONNECTION_STRING:-DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;}"

mkdir -p "$AZURE_CONFIG_DIR"

echo "Checking LocalStack..."
curl -fsS "$LOCALSTACK_HEALTH_URL" | python3 -m json.tool

echo
echo "Checking Azurite HTTP endpoint..."
curl -sSI "$AZURITE_BLOB_URL" | sed -n '1,10p'

echo
echo "Checking Azurite authenticated data plane..."
AZURITE_CONNECTION_STRING="$AZURITE_CONNECTION_STRING" \
python3 "$ROOT_DIR/scripts/azurite_storage.py" verify \
  --api-version "$AZURE_STORAGE_API_VERSION" > /dev/null
echo "Azurite authenticated data plane is reachable"

echo
echo "Both emulators are reachable."
