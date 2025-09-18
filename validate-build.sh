#!/bin/bash

# Validate build environment and Docker setup
# This script helps diagnose build issues before running the full build

set -e

echo "🔍 KCPTube Build Environment Validation"
echo "========================================"

# Check Docker
echo ""
echo "1. Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

DOCKER_VERSION=$(docker --version)
echo "✅ Docker found: $DOCKER_VERSION"

# Test Docker connectivity
echo ""
echo "2. Testing Docker connectivity..."
if docker info > /dev/null 2>&1; then
    echo "✅ Docker daemon is running"
else
    echo "❌ Cannot connect to Docker daemon"
    exit 1
fi

# Test Alpine image download
echo ""
echo "3. Testing Alpine image access..."
if docker pull alpine:3.20 > /dev/null 2>&1; then
    echo "✅ Can pull Alpine 3.20 image"
else
    echo "❌ Cannot pull Alpine 3.20 image"
    exit 1
fi

# Test Alpine package repositories
echo ""
echo "4. Testing Alpine package repositories..."
TEST_OUTPUT=$(docker run --rm alpine:3.20 sh -c "
    echo 'https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/main' > /etc/apk/repositories &&
    echo 'https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/community' >> /etc/apk/repositories &&
    echo 'https://dl-cdn.alpinelinux.org/alpine/v3.20/main' >> /etc/apk/repositories &&
    echo 'https://dl-cdn.alpinelinux.org/alpine/v3.20/community' >> /etc/apk/repositories &&
    timeout 30 apk update 2>&1
" 2>&1) || true

if echo "$TEST_OUTPUT" | grep -q "OK:"; then
    echo "✅ Alpine package repositories accessible"
else
    echo "⚠️  Alpine package repositories may have issues:"
    echo "$TEST_OUTPUT" | head -3 | sed 's/^/   /'
fi

# Test basic package availability
echo ""
echo "5. Testing package availability..."
PACKAGES_TEST=$(docker run --rm alpine:3.20 sh -c "
    echo 'https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/main' > /etc/apk/repositories &&
    echo 'https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/community' >> /etc/apk/repositories &&
    echo 'https://dl-cdn.alpinelinux.org/alpine/v3.20/main' >> /etc/apk/repositories &&
    echo 'https://dl-cdn.alpinelinux.org/alpine/v3.20/community' >> /etc/apk/repositories &&
    timeout 30 apk update > /dev/null 2>&1 &&
    apk search build-base 2>&1 | head -1 &&
    apk search cmake 2>&1 | head -1 &&
    apk search botan-dev 2>&1 | head -1
" 2>&1) || true

if echo "$PACKAGES_TEST" | grep -q "build-base"; then
    echo "✅ Required packages found"
    echo "   Found packages:"
    echo "$PACKAGES_TEST" | grep -E "(build-base|cmake|botan)" | sed 's/^/   /'
else
    echo "⚠️  Some packages may not be available:"
    echo "$PACKAGES_TEST" | head -5 | sed 's/^/   /'
fi

# Check git connectivity
echo ""
echo "6. Testing Git repository access..."
if timeout 10 git ls-remote https://github.com/cnbatch/kcptube.git > /dev/null 2>&1; then
    echo "✅ Can access cnbatch/kcptube repository"
else
    echo "⚠️  May have issues accessing cnbatch/kcptube repository"
fi

# Check available disk space
echo ""
echo "7. Checking disk space..."
AVAILABLE_SPACE=$(df -h . | tail -1 | awk '{print $4}')
echo "Available disk space: $AVAILABLE_SPACE"

if df . | tail -1 | awk '{print $4}' | awk '{if($1 > 2000000) exit 0; else exit 1}'; then
    echo "✅ Sufficient disk space available"
else
    echo "⚠️  Low disk space - build may fail"
fi

echo ""
echo "🎉 Validation completed!"
echo ""
echo "Summary:"
echo "- If all items show ✅, you should be able to build successfully"
echo "- Items marked with ⚠️  may cause build issues but might still work"
echo "- Items marked with ❌ will likely cause build failures"
echo ""
echo "To run the build: ./test-build.sh"
echo "For troubleshooting: ./troubleshoot.sh"