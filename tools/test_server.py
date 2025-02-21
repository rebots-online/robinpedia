from http.server import HTTPServer, SimpleHTTPRequestHandler
import os

class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

def run(port=8000):
    # Create test files if they don't exist
    os.makedirs('test_files', exist_ok=True)
    
    # Create dummy ZIM files for testing
    for filename in ['wikipedia_en_test_2024.zim', 'wiktionary_en_test_2024.zim']:
        filepath = os.path.join('test_files', filename)
        if not os.path.exists(filepath):
            with open(filepath, 'wb') as f:
                # Create a 1MB file for Wikipedia and 0.5MB for Wiktionary
                size = 1024 * 1024 if 'wikipedia' in filename else 512 * 1024
                f.write(b'0' * size)

    # Change to the test_files directory
    os.chdir('test_files')
    
    server_address = ('', port)
    httpd = HTTPServer(server_address, CORSRequestHandler)
    print(f'Starting test server on port {port}...')
    httpd.serve_forever()

if __name__ == '__main__':
    run()
