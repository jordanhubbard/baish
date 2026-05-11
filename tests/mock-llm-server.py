#!/usr/bin/env python3
"""
Simple mock LLM server for testing baish ask builtin.

Usage:
    python3 mock-llm-server.py [port] [host]

Returns mock responses in OpenAI-compatible format.
"""

import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

class MockLLMHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

    def _send_json(self, status, payload):
        data = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header('Content-type', 'application/json')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _extract_prompt(self, request_data):
        messages = request_data.get('messages')
        if isinstance(messages, list):
            for message in reversed(messages):
                if not isinstance(message, dict):
                    continue
                if message.get('role') != 'user':
                    continue
                content = message.get('content', '')
                if isinstance(content, str):
                    return content

        inputs = request_data.get('input')
        if isinstance(inputs, list):
            for item in reversed(inputs):
                if not isinstance(item, dict):
                    continue
                if item.get('role') != 'user':
                    continue
                content = item.get('content', '')
                if isinstance(content, str):
                    return content

        return ''

    def do_GET(self):
        """Handle GET requests (for /models preflight check)"""
        if self.path == '/models' or self.path == '/v1/models':
            self._send_json(200, {
                'object': 'list',
                'data': [
                    {'id': 'test-model', 'object': 'model'},
                    {'id': 'mock-model', 'object': 'model'}
                ]
            })
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        """Handle POST requests (for chat completions)"""
        if '/chat/completions' in self.path or '/completions' in self.path:
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)

            try:
                request_data = json.loads(body)
                prompt = self._extract_prompt(request_data)

                # Generate mock response based on prompt
                if 'list files' in prompt.lower():
                    answer = "To list files by size, use: ls -lhS"
                    commands = ["ls -lhS"]
                    content = {'answer': answer, 'commands': commands}
                elif 'alternate response key' in prompt.lower():
                    content = {
                        'response': 'Alternate response key worked',
                        'commands': []
                    }
                elif 'disk usage' in prompt.lower():
                    answer = "Show disk usage with du command"
                    commands = ["du -sh *"]
                    content = {'answer': answer, 'commands': commands}
                else:
                    answer = f"Mock response to: {prompt[:50]}..."
                    commands = []
                    content = {'answer': answer, 'commands': commands}

                response = {
                    'id': 'mock-response',
                    'object': 'chat.completion',
                    'model': request_data.get('model', 'test-model'),
                    'choices': [{
                        'message': {
                            'role': 'assistant',
                            'content': json.dumps(content)
                        }
                    }]
                }

                self._send_json(200, response)
            except Exception as e:
                self._send_json(500, {'error': str(e)})
        else:
            self.send_response(404)
            self.end_headers()

def run_server(port=8080, host=''):
    server_address = (host, port)
    httpd = HTTPServer(server_address, MockLLMHandler)
    display_host = host or 'localhost'
    print(f'Mock LLM server running on http://{display_host}:{port}')
    print('Press Ctrl+C to stop')
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\nShutting down...')
        httpd.shutdown()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    host = sys.argv[2] if len(sys.argv) > 2 else ''
    run_server(port, host)
