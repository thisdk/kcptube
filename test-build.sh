#!/bin/bash

# Build and test KCPTube Docker image
set -e

echo "Building KCPTube Docker image..."
docker build -t kcptube-local .

echo "Testing the image..."
# Test 1: Check if kcptube binary is available and shows help
docker run --rm kcptube-local --help || {
    echo "Error: KCPTube binary not working properly"
    exit 1
}

# Test 2: Check if config validation works
cat > test-config.conf << EOF
mode=client
kcp=regular3
listen_port=59000
destination_port=3000
destination_address=127.0.0.1
EOF

echo "Testing config validation..."
docker run --rm -v "$(pwd)/test-config.conf:/etc/kcptube/test.conf:ro" \
    kcptube-local --check-config /etc/kcptube/test.conf || {
    echo "Error: Config validation failed"
    exit 1
}

# Clean up test file
rm -f test-config.conf

echo "✅ All tests passed! Docker image built successfully."
echo "Image name: kcptube-local"
echo ""
echo "Usage examples:"
echo "  docker run --rm kcptube-local --help"
echo "  docker run -v /path/to/config.conf:/etc/kcptube/config.conf:ro kcptube-local /etc/kcptube/config.conf"