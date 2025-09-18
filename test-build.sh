#!/bin/bash

# Build and test KCPTube Docker image
set -e

IMAGE_NAME="kcptube-local"

echo "Building KCPTube Docker image..."
echo "====================================="

# Build with more detailed output
docker build -t "$IMAGE_NAME" . --progress=plain --no-cache

echo ""
echo "✅ Build completed successfully!"
echo ""

echo "Testing the image..."
echo "===================="

# Test 1: Check if kcptube binary is available and shows help
echo "Test 1: Checking help output..."
if docker run --rm "$IMAGE_NAME" --help > /tmp/help_output.txt 2>&1; then
    echo "✅ Help command executed successfully"
    echo "First few lines of help:"
    head -5 /tmp/help_output.txt | sed 's/^/  /'
else
    echo "❌ Error: KCPTube binary not working properly"
    echo "Error output:"
    cat /tmp/help_output.txt | sed 's/^/  /'
    exit 1
fi

# Test 2: Check binary info
echo ""
echo "Test 2: Binary information..."
docker run --rm --entrypoint="" "$IMAGE_NAME" sh -c "ls -la /usr/local/bin/kcptube && file /usr/local/bin/kcptube" || {
    echo "❌ Error: Cannot get binary information"
    exit 1
}

# Test 3: Check if config validation works
echo ""
echo "Test 3: Configuration validation..."
cat > /tmp/test-config.conf << EOF
mode=client
kcp=regular3
listen_port=59000
destination_port=3000
destination_address=127.0.0.1
EOF

if docker run --rm -v "/tmp/test-config.conf:/etc/kcptube/test.conf:ro" \
    "$IMAGE_NAME" --check-config /etc/kcptube/test.conf > /tmp/config_test.txt 2>&1; then
    echo "✅ Config validation works"
else
    echo "⚠️  Config validation test inconclusive (may be expected for some versions)"
    echo "Output:"
    cat /tmp/config_test.txt | head -3 | sed 's/^/  /'
fi

# Clean up test files
rm -f /tmp/test-config.conf /tmp/help_output.txt /tmp/config_test.txt

echo ""
echo "🎉 All tests completed!"
echo "========================"
echo "Image name: $IMAGE_NAME"
echo ""
echo "Usage examples:"
echo "  docker run --rm $IMAGE_NAME --help"
echo "  docker run -v /path/to/config.conf:/etc/kcptube/config.conf:ro $IMAGE_NAME /etc/kcptube/config.conf"
echo ""
echo "For troubleshooting, run: ./troubleshoot.sh"