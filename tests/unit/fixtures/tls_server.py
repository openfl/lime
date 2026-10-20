"""Loopback HTTPS fixture. The parent owns its lifetime through stdin."""

import http.server
import socket
import socketserver
import ssl
import sys
import threading


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Length", "2")
        self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(b"ok")
        self.close_connection = True

    def log_message(self, *_args):
        pass


class Server(http.server.ThreadingHTTPServer):
    daemon_threads = True

    def server_bind(self):
        # HTTPServer resolves a hostname here; this loopback fixture needs no DNS.
        socketserver.TCPServer.server_bind(self)
        self.server_name, self.server_port = self.server_address

    def get_request(self):
        connection, address = super().get_request()
        connection.settimeout(5)
        try:
            return self.context.wrap_socket(connection, server_side=True), address
        except BaseException:
            connection.close()
            raise

    def handle_error(self, _request, _address):
        # A certificate rejection or client disconnect is expected in these tests.
        error = sys.exc_info()[1]
        if not isinstance(error, (ConnectionError, ssl.SSLError, socket.timeout)):
            super().handle_error(_request, _address)


def main():
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(sys.argv[1], sys.argv[2])
    with Server(("127.0.0.1", 0), Handler) as server:
        server.context = context
        worker = threading.Thread(target=server.serve_forever, daemon=True)
        worker.start()
        print(server.server_port, flush=True)
        try:
            sys.stdin.buffer.read(1)
        finally:
            server.shutdown()
            worker.join(timeout=6)


if __name__ == "__main__":
    main()
