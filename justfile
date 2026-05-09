test:
    zig build test --summary all

build:
    zig build --summary all

docs:
    zig build docs --summary all

open-docs: docs
    @echo "View docs at http://localhost:8000"
    python3 -m http.server 8000 -d zig-out/docs/
