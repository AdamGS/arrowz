test:
    zig build test --summary all

integration:
    zig build integration --summary all

test-all: test integration

build:
    zig build --summary all

docs:
    zig build docs --summary all

open-docs: docs
    @echo "View docs at http://localhost:8000"
    python3 -m http.server 8000 -d zig-out/docs/
