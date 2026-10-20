# HTTPS fixture

The Neko HTTPS tests use Python 3's standard `ssl` and `http.server` modules for
their loopback server. CI installs Python 3.12 and passes its executable path.
Locally, the tests run `python` on
Windows or `python3` elsewhere; `LIME_TEST_PYTHON` can name another executable.
No Python packages or external network service are needed for the local tests.
The C++ and HashLink tests retain their existing Haxe server fixture.

The server is embedded as a Haxe resource so it is available before Lime finishes
loading its asset libraries. Each instance writes the existing test certificate
and key to a temporary directory, binds only `127.0.0.1` on an assigned port, and
reports that port to the parent. The parent closes the server through stdin,
waits for its process to exit, and removes its temporary files. Closing the parent
also closes stdin, which stops the server.

Binding uses the numeric loopback address without HTTPServer's reverse hostname
lookup, so starting the fixture does not depend on the runner's DNS service.
Run its Python regression test with `python -m unittest discover -s fixtures`
from `tests/unit`; CI runs it before the native tests.

Keeping the server outside the test process isolates its TLS implementation and
signal handling. In particular, rejecting a certificate must not send `SIGPIPE`
through Neko's SSL server and interrupt the Lime client under test. The repeated
rejection test also verifies that a subsequent accepted request still succeeds.
