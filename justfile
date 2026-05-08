test:
    zig build test --summary all

build:
    zig build

docs:
    zig build docs

open-docs: docs
    @echo "View docs at http://localhost:8000"
    python3 -m http.server 8000 -d zig-out/docs/
