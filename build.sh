#!/bin/bash

# Comprehensive build script for KCPTube Docker image
# This script provides multiple build options and strategies

set -e

# Configuration
IMAGE_NAME="${1:-kcptube-local}"
BUILD_STRATEGY="${BUILD_STRATEGY:-auto}"
NO_CACHE="${NO_CACHE:-false}"

echo "🚀 KCPTube Docker 镜像构建脚本"
echo "================================="
echo "镜像名称: $IMAGE_NAME"
echo "构建策略: $BUILD_STRATEGY"
echo "无缓存构建: $NO_CACHE"
echo ""

# Function to show usage
show_usage() {
    echo "用法: $0 [IMAGE_NAME]"
    echo ""
    echo "环境变量:"
    echo "  BUILD_STRATEGY=auto|fast|safe|debug"
    echo "  NO_CACHE=true|false"
    echo ""
    echo "示例:"
    echo "  $0                          # 使用默认设置"
    echo "  $0 my-kcptube              # 指定镜像名"
    echo "  BUILD_STRATEGY=fast $0      # 快速构建"
    echo "  NO_CACHE=true $0           # 无缓存构建"
}

# Function to build with different strategies
build_image() {
    local strategy=$1
    local docker_args=()
    
    if [[ "$NO_CACHE" == "true" ]]; then
        docker_args+=(--no-cache)
    fi
    
    case $strategy in
        "fast")
            echo "🏃 快速构建策略 - 使用缓存，单平台"
            docker_args+=(--progress=plain)
            ;;
        "safe")
            echo "🛡️  安全构建策略 - 详细输出，错误时停止"
            docker_args+=(--progress=plain --no-cache)
            ;;
        "debug")
            echo "🐛 调试构建策略 - 最大详细输出"
            docker_args+=(--progress=plain --no-cache --build-arg VERBOSE=1)
            ;;
        "auto"|*)
            echo "🤖 自动构建策略 - 平衡速度和可靠性"
            docker_args+=(--progress=auto)
            ;;
    esac
    
    echo "执行构建命令: docker build ${docker_args[*]} -t $IMAGE_NAME ."
    echo ""
    
    # Record build start time
    BUILD_START=$(date +%s)
    
    # Build the image
    if docker build "${docker_args[@]}" -t "$IMAGE_NAME" .; then
        BUILD_END=$(date +%s)
        BUILD_TIME=$((BUILD_END - BUILD_START))
        echo ""
        echo "✅ 构建成功完成！"
        echo "构建时间: ${BUILD_TIME}秒"
        
        # Get image size
        IMAGE_SIZE=$(docker images "$IMAGE_NAME" --format "table {{.Size}}" | tail -n +2)
        echo "镜像大小: $IMAGE_SIZE"
        return 0
    else
        echo ""
        echo "❌ 构建失败"
        return 1
    fi
}

# Function to run basic tests
run_tests() {
    echo ""
    echo "🧪 运行基础测试..."
    echo "=================="
    
    # Test 1: Help command
    echo "测试 1: 帮助命令"
    if timeout 30 docker run --rm "$IMAGE_NAME" --help > /tmp/build_test_help.txt 2>&1; then
        echo "✅ 帮助命令成功"
        echo "输出摘要:"
        head -3 /tmp/build_test_help.txt | sed 's/^/  /'
    else
        echo "❌ 帮助命令失败"
        echo "错误输出:"
        cat /tmp/build_test_help.txt | head -5 | sed 's/^/  /'
        return 1
    fi
    
    # Test 2: Binary verification
    echo ""
    echo "测试 2: 二进制验证"
    if docker run --rm --entrypoint="" "$IMAGE_NAME" sh -c "file /usr/local/bin/kcptube && ldd /usr/local/bin/kcptube" > /tmp/build_test_binary.txt 2>&1; then
        echo "✅ 二进制验证成功"
        echo "二进制信息:"
        cat /tmp/build_test_binary.txt | sed 's/^/  /'
    else
        echo "❌ 二进制验证失败"
        cat /tmp/build_test_binary.txt | sed 's/^/  /'
        return 1
    fi
    
    # Clean up test files
    rm -f /tmp/build_test_help.txt /tmp/build_test_binary.txt
    
    echo ""
    echo "🎉 所有测试通过！"
    return 0
}

# Function to show build summary
show_summary() {
    echo ""
    echo "📋 构建摘要"
    echo "============"
    echo "镜像名称: $IMAGE_NAME"
    
    # Image details
    if docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
        CREATED=$(docker image inspect "$IMAGE_NAME" --format '{{.Created}}' | cut -d'T' -f1)
        SIZE=$(docker image inspect "$IMAGE_NAME" --format '{{.Size}}' | numfmt --to=iec)
        ARCH=$(docker image inspect "$IMAGE_NAME" --format '{{.Architecture}}')
        
        echo "创建时间: $CREATED"
        echo "镜像大小: $SIZE"
        echo "架构: $ARCH"
        echo ""
        echo "使用方法:"
        echo "========="
        echo "# 查看帮助"
        echo "docker run --rm $IMAGE_NAME --help"
        echo ""
        echo "# 运行客户端"
        echo "docker run -d \\"
        echo "  --name kcptube \\"
        echo "  -p 59000:59000/udp \\"
        echo "  -v /path/to/config.conf:/etc/kcptube/config.conf:ro \\"
        echo "  $IMAGE_NAME /etc/kcptube/config.conf"
        echo ""
        echo "# 故障排查"
        echo "./troubleshoot.sh"
    else
        echo "❌ 镜像不存在或损坏"
        return 1
    fi
}

# Main execution
main() {
    case "${1:-}" in
        "-h"|"--help"|"help")
            show_usage
            exit 0
            ;;
    esac
    
    echo "开始构建..."
    
    # Validate environment first
    if [[ -f "./validate-build.sh" ]]; then
        echo "🔍 运行构建环境验证..."
        if ./validate-build.sh; then
            echo "✅ 环境验证通过"
        else
            echo "⚠️  环境验证发现问题，但继续构建..."
        fi
        echo ""
    fi
    
    # Build the image
    if build_image "$BUILD_STRATEGY"; then
        # Run tests
        if run_tests; then
            # Show summary
            show_summary
            echo ""
            echo "🏆 构建和测试全部完成！"
            exit 0
        else
            echo "⚠️  构建成功但测试失败"
            exit 1
        fi
    else
        echo "💥 构建失败"
        echo ""
        echo "故障排查建议:"
        echo "1. 检查网络连接: ping -c 3 dl-cdn.alpinelinux.org"
        echo "2. 检查磁盘空间: df -h"
        echo "3. 运行环境验证: ./validate-build.sh"
        echo "4. 查看详细错误: BUILD_STRATEGY=debug $0"
        exit 1
    fi
}

# Call main function
main "$@"