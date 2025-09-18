#!/bin/bash

# KCPTube Docker 故障排查工具
# KCPTube Docker Troubleshooting Tool

echo "KCPTube Docker 故障排查工具 v2.0"
echo "==================================="

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装或不在 PATH 中"
    echo "请安装 Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✅ Docker 已安装: $(docker --version)"

# 检查 Docker 服务状态
if ! docker info &> /dev/null; then
    echo "❌ Docker 服务未运行"
    echo "请启动 Docker 服务"
    exit 1
fi

echo "✅ Docker 服务正常运行"

# 检查镜像是否存在
IMAGE_NAME="ghcr.io/thisdk/kcptube:latest"
LOCAL_IMAGE="kcptube-local"

echo ""
echo "镜像检查..."
echo "============"

# 检查本地构建的镜像
if docker image inspect "$LOCAL_IMAGE" &> /dev/null; then
    echo "✅ 本地构建镜像存在: $LOCAL_IMAGE"
    USE_IMAGE="$LOCAL_IMAGE"
elif docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "✅ 官方镜像存在: $IMAGE_NAME"
    USE_IMAGE="$IMAGE_NAME"
else
    echo "📥 镜像不存在，正在拉取..."
    if docker pull "$IMAGE_NAME"; then
        echo "✅ 成功拉取镜像: $IMAGE_NAME"
        USE_IMAGE="$IMAGE_NAME"
    else
        echo "❌ 拉取镜像失败"
        echo ""
        echo "解决方案："
        echo "1. 检查网络连接"
        echo "2. 尝试本地构建: ./test-build.sh"
        echo "3. 或运行验证脚本: ./validate-build.sh"
        exit 1
    fi
fi

# 测试镜像基本功能
echo ""
echo "测试镜像基本功能..."
echo "===================="

# 测试 1: 帮助信息
echo "测试 1: 显示帮助信息"
if timeout 30 docker run --rm "$USE_IMAGE" --help > /tmp/kcptube_help.txt 2>&1; then
    echo "✅ 帮助信息正常"
    echo "   输出摘要:"
    head -3 /tmp/kcptube_help.txt | sed 's/^/   /'
else
    echo "❌ 帮助信息异常"
    echo "   错误输出:"
    cat /tmp/kcptube_help.txt | head -5 | sed 's/^/   /'
fi

# 测试 2: 二进制文件信息
echo ""
echo "测试 2: 二进制文件信息"
if docker run --rm --entrypoint="" "$USE_IMAGE" sh -c "ls -la /usr/local/bin/kcptube && file /usr/local/bin/kcptube" > /tmp/binary_info.txt 2>&1; then
    echo "✅ 二进制文件正常"
    echo "   信息:"
    cat /tmp/binary_info.txt | sed 's/^/   /'
else
    echo "❌ 二进制文件异常"
    echo "   错误:"
    cat /tmp/binary_info.txt | sed 's/^/   /'
fi

# 测试 3: 配置验证功能
echo ""
echo "测试 3: 配置验证功能"
cat > /tmp/test-config.conf << 'EOF'
mode=client
kcp=regular3
listen_port=59000
destination_port=3000
destination_address=127.0.0.1
EOF

if timeout 15 docker run --rm -v /tmp/test-config.conf:/etc/kcptube/test.conf:ro \
   "$USE_IMAGE" --check-config /etc/kcptube/test.conf > /tmp/config_test.txt 2>&1; then
    echo "✅ 配置验证正常"
else
    echo "⚠️  配置验证测试未通过 (某些版本可能不支持此选项)"
    echo "   输出:"
    head -3 /tmp/config_test.txt | sed 's/^/   /'
fi

# 清理测试文件
rm -f /tmp/test-config.conf /tmp/kcptube_help.txt /tmp/binary_info.txt /tmp/config_test.txt

echo ""
echo "网络检查..."
echo "============"

# 检查常用 UDP 端口是否被占用
check_port() {
    local port=$1
    if netstat -ul 2>/dev/null | grep ":$port " > /dev/null; then
        echo "⚠️  端口 $port 已被占用"
        return 1
    else
        echo "✅ 端口 $port 可用"
        return 0
    fi
}

check_port 3000
check_port 59000

echo ""
echo "系统信息..."
echo "============"
echo "操作系统: $(uname -s)"
echo "架构: $(uname -m)"
echo "内核版本: $(uname -r)"

# 检查磁盘空间
AVAILABLE_SPACE=$(df -h . | tail -1 | awk '{print $4}')
echo "可用磁盘空间: $AVAILABLE_SPACE"

echo ""
echo "故障排查完成！"
echo ""
echo "常见问题解决方案:"
echo "=================="
echo "1. 端口被占用: 修改配置文件中的端口号"
echo "2. 权限问题: 确保配置文件可读"
echo "3. 网络问题: 检查防火墙设置"
echo "4. 配置问题: 使用 --check-config 验证配置文件"
echo "5. 构建问题: 运行 ./validate-build.sh 检查构建环境"
echo ""
echo "使用示例:"
echo "=========="
echo "# 启动客户端"
echo "docker run -d \\"
echo "  --name kcptube-client \\"
echo "  -p 59000:59000/udp \\"
echo "  -v /path/to/client.conf:/etc/kcptube/config.conf:ro \\"
echo "  $USE_IMAGE /etc/kcptube/config.conf"
echo ""
echo "# 查看日志"
echo "docker logs kcptube-client"
echo ""
echo "更多帮助请访问: https://github.com/thisdk/kcptube"