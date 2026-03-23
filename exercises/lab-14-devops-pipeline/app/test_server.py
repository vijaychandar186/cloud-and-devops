import unittest
import json
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from unittest.mock import MagicMock, patch
import server

class TestHandler(unittest.TestCase):
    def _make_handler(self, path):
        handler = server.Handler.__new__(server.Handler)
        handler.path = path
        handler.wfile = MagicMock()
        handler.send_response = MagicMock()
        handler.send_header = MagicMock()
        handler.end_headers = MagicMock()
        return handler

    def test_health_endpoint(self):
        h = self._make_handler("/health")
        h.do_GET()
        h.send_response.assert_called_once_with(200)
        call_args = h.wfile.write.call_args[0][0]
        data = json.loads(call_args.decode())
        self.assertEqual(data["status"], "ok")
        self.assertEqual(data["lab"], "14")

    def test_root_endpoint(self):
        h = self._make_handler("/")
        h.do_GET()
        h.send_response.assert_called_once_with(200)
        call_args = h.wfile.write.call_args[0][0]
        self.assertIn(b"Lab 14", call_args)

if __name__ == "__main__":
    unittest.main()
