function serve --description 'Serve the current directory over HTTP (serve [port])'
    set -l port 8000
    test (count $argv) -gt 0; and set port $argv[1]
    python3 -m http.server $port
end
