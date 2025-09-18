#!/bin/bash

# KCPTube Docker 故障排查工具
# KCPTube Docker Troubleshooting Tool

echo "KCPTube Docker 故障排查工具 v1.0"
echo "=================================="

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker 未安装或不在 PATH 中"
    exit 1
fi

echo "✅ Docker 已安装: $(docker --version)"

# 检查镜像是否存在
IMAGE_NAME="ghcr.io/thisdk/kcptube:latest"
if docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "✅ KCPTube 镜像已存在"
else
    echo "❌ KCPTube 镜像不存在，正在拉取..."
    docker pull "$IMAGE_NAME" || {
        echo "❌ 拉取镜像失败"
        exit 1
    }
fi

# 测试镜像基本功能
echo ""
echo "测试镜像基本功能..."
echo "==================="

# 测试 1: 帮助信息
echo "测试 1: 显示帮助信息"
if docker run --rm "$IMAGE_NAME" --help > /dev/null 2>&1; then
    echo "✅ 帮助信息正常"
else
    echo "❌ 帮助信息异常"
fi

# 测试 2: 配置验证功能
echo "测试 2: 配置验证功能"
cat > /tmp/test-config.conf << 'EOF'
mode=client
kcp=regular3
listen_port=59000
destination_port=3000
destination_address=127.0.0.1
EOF

if docker run --rm -v /tmp/test-config.conf:/etc/kcptube/test.conf:ro \
   "$IMAGE_NAME" --check-config /etc/kcptube/test.conf > /dev/null 2>&1; then
    echo "✅ 配置验证正常"
else
    echo "❌ 配置验证异常"
fi

# 清理测试文件
rm -f /tmp/test-config.conf

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

echo ""
echo "故障排查完成！"
echo ""
echo "常见问题解决方案:"
echo "=================="
echo "1. 端口被占用: 修改配置文件中的端口号"
echo "2. 权限问题: 确保配置文件可读"
echo "3. 网络问题: 检查防火墙设置"
echo "4. 配置问题: 使用 --check-config 验证配置文件"
echo ""
echo "更多帮助请访问: https://github.com/thisdk/kcptube"