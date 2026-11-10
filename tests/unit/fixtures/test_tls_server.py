import socket
import unittest
from unittest.mock import patch

from tls_server import Handler, Server


class ServerTest(unittest.TestCase):
    def test_binding_does_not_resolve_hostnames(self):
        with patch.object(socket, "getfqdn", side_effect=AssertionError("DNS unavailable")):
            with Server(("127.0.0.1", 0), Handler) as server:
                self.assertEqual(server.server_name, "127.0.0.1")
                self.assertGreater(server.server_port, 0)
                self.assertEqual(server.server_port, server.socket.getsockname()[1])


if __name__ == "__main__":
    unittest.main()
