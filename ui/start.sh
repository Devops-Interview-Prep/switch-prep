#!/bin/bash
set -e
cd "$(dirname "$0")"

echo ""
echo "  Switch Prep UI — DevOps Interview Notes"
echo ""

# Install dependencies
if ! python3 -c "import flask" 2>/dev/null; then
    echo "  Installing dependencies..."
    pip3 install -q flask --break-system-packages 2>/dev/null || pip3 install -q flask
fi

python3 app.py
