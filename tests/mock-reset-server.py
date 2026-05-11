#!/usr/bin/env python3
"""Accept TCP connections and close them with RST.

Used to simulate a broken IPv6 localhost listener while the real mock API is
available on IPv4 localhost.
"""

import socket
import struct
import sys


def run_server(port=8080, host='::1'):
    sock = socket.socket(socket.AF_INET6, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
    sock.bind((host, port))
    sock.listen(16)
    print(f'Reset server running on [{host}]:{port}', flush=True)

    while True:
        conn, _addr = sock.accept()
        conn.setsockopt(socket.SOL_SOCKET, socket.SO_LINGER, struct.pack('ii', 1, 0))
        conn.close()


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    host = sys.argv[2] if len(sys.argv) > 2 else '::1'
    run_server(port, host)
