# KCPTube Docker 镜像

[![Docker Build](https://github.com/thisdk/kcptube/actions/workflows/docker-build.yml/badge.svg)](https://github.com/thisdk/kcptube/actions/workflows/docker-build.yml)
[![Docker Image Size](https://img.shields.io/docker/image-size/ghcr.io/thisdk/kcptube/latest)](https://github.com/thisdk/kcptube/pkgs/container/kcptube)

这个仓库用于编译 [cnbatch/kcptube](https://github.com/cnbatch/kcptube) 为 Docker 镜像并发布到 GitHub Container Registry。

## 关于 KCPTube

KCPTube 是一个基于 KCP 协议的网络代理工具，用于优化 UDP 连接，特别适合在网络环境较差的情况下提供可靠的数据传输。主要特性包括：

- 支持 TCP 和 UDP 流量转发
- 基于 KCP 协议的可靠重传
- 支持多种加密算法（AES-GCM、ChaCha20 等）
- 支持 STUN 打洞
- 多种工作模式（客户端、服务端、中继节点）

## 快速开始

详细部署指南请参考 [DEPLOYMENT.md](DEPLOYMENT.md)

### 拉取镜像

```bash
docker pull ghcr.io/thisdk/kcptube:latest
```

### 基本使用

1. **创建配置文件**

创建一个配置文件 `config.conf`，例如客户端配置：

```ini
mode=client
kcp=regular3
inbound_bandwidth=500M
outbound_bandwidth=50M
listen_port=59000
destination_port=3000
destination_address=123.45.67.89
encryption_password=qwerty1234
encryption_algorithm=AES-GCM
```

2. **运行容器**

```bash
docker run -d \
  --name kcptube \
  -p 59000:59000/udp \
  -v /path/to/your/config.conf:/etc/kcptube/config.conf:ro \
  ghcr.io/thisdk/kcptube:latest \
  /etc/kcptube/config.conf
```

### 服务端模式示例

服务端配置文件 `server.conf`：

```ini
mode=server
kcp=regular3
inbound_bandwidth=1G
outbound_bandwidth=1G
listen_port=3000
destination_port=59000
destination_address=::1
encryption_password=qwerty1234
encryption_algorithm=AES-GCM
stun_server=stun.qq.com
log_path=/var/log/kcptube/
```

运行服务端：

```bash
docker run -d \
  --name kcptube-server \
  -p 3000:3000/udp \
  -v /path/to/server.conf:/etc/kcptube/config.conf:ro \
  -v /path/to/logs:/var/log/kcptube \
  ghcr.io/thisdk/kcptube:latest \
  /etc/kcptube/config.conf
```

### Docker Compose 示例

创建 `docker-compose.yml`：

```yaml
version: '3.8'

services:
  kcptube-client:
    image: ghcr.io/thisdk/kcptube:latest
    container_name: kcptube-client
    ports:
      - "59000:59000/udp"
    volumes:
      - ./client.conf:/etc/kcptube/config.conf:ro
    command: ["/etc/kcptube/config.conf"]
    restart: unless-stopped

  kcptube-server:
    image: ghcr.io/thisdk/kcptube:latest
    container_name: kcptube-server
    ports:
      - "3000:3000/udp"
    volumes:
      - ./server.conf:/etc/kcptube/config.conf:ro
      - ./logs:/var/log/kcptube
    command: ["/etc/kcptube/config.conf"]
    restart: unless-stopped
```

运行：

```bash
docker-compose up -d
```

## 配置说明

KCPTube 支持丰富的配置选项，以下是主要参数：

### 基础参数

| 参数名 | 说明 | 示例值 |
|-------|------|--------|
| `mode` | 运行模式 | `client`、`server`、`relay` |
| `listen_port` | 监听端口 | `3000` 或 `3000-4000` |
| `destination_address` | 目标地址 | IP 地址或域名 |
| `destination_port` | 目标端口 | `3000` 或 `3000-4000` |

### KCP 参数

| 参数名 | 说明 | 可选值 |
|-------|------|--------|
| `kcp` | KCP 模式 | `fast1-6`、`regular1-5`、`manual` |
| `kcp_mtu` | MTU 大小 | 默认 1440 |
| `inbound_bandwidth` | 入站带宽 | 如 `100M`、`1G` |
| `outbound_bandwidth` | 出站带宽 | 如 `50M`、`500M` |

### 加密参数

| 参数名 | 说明 | 可选值 |
|-------|------|--------|
| `encryption_algorithm` | 加密算法 | `AES-GCM`、`chacha20`、`none` |
| `encryption_password` | 加密密码 | 任意字符串 |

更多配置选项请参考 [原项目文档](https://github.com/cnbatch/kcptube/wiki)。

## 环境变量

容器还支持通过环境变量进行配置：

```bash
docker run -d \
  --name kcptube \
  -p 59000:59000/udp \
  -e KCPTUBE_MODE=client \
  -e KCPTUBE_LISTEN_PORT=59000 \
  -e KCPTUBE_DEST_ADDR=123.45.67.89 \
  -e KCPTUBE_DEST_PORT=3000 \
  ghcr.io/thisdk/kcptube:latest
```

## 镜像标签

| 标签 | 说明 |
|------|------|
| `latest` | 最新版本，基于 main 分支构建 |
| `v1.0.0` | 特定版本标签 |
| `main-<sha>` | 基于特定提交构建 |

## 支持的架构

- `linux/amd64`
- `linux/arm64`

## 故障排查

使用提供的故障排查脚本：

```bash
# 下载并运行故障排查脚本
curl -sSL https://raw.githubusercontent.com/thisdk/kcptube/main/troubleshoot.sh | bash
```

或者：

```bash
# 下载脚本
wget https://raw.githubusercontent.com/thisdk/kcptube/main/troubleshoot.sh
chmod +x troubleshoot.sh
./troubleshoot.sh
```

### 查看日志

```bash
docker logs kcptube
```

### 测试配置

```bash
# 验证配置文件
docker run --rm \
  -v /path/to/config.conf:/etc/kcptube/config.conf:ro \
  ghcr.io/thisdk/kcptube:latest \
  --check-config /etc/kcptube/config.conf

# 测试连接
docker run --rm \
  -v /path/to/config.conf:/etc/kcptube/config.conf:ro \
  ghcr.io/thisdk/kcptube:latest \
  --try /etc/kcptube/config.conf
```

### 常见问题

1. **端口访问问题**: 确保 Docker 端口映射正确，UDP 端口需要指定协议类型
2. **权限问题**: 容器以非 root 用户运行，确保挂载的目录权限正确
3. **配置文件问题**: 使用 `--check-config` 验证配置文件语法

## 构建镜像

如需自行构建镜像，有多种构建选项可用：

### 快速构建

```bash
git clone https://github.com/thisdk/kcptube.git
cd kcptube

# 使用改进的构建脚本（推荐）
./build.sh

# 或使用传统方式
./test-build.sh
```

### 构建选项

新的构建系统提供多种策略：

```bash
# 快速构建（使用缓存）
BUILD_STRATEGY=fast ./build.sh

# 安全构建（无缓存，详细输出）
BUILD_STRATEGY=safe ./build.sh

# 调试构建（最详细输出）
BUILD_STRATEGY=debug ./build.sh

# 完全重新构建
NO_CACHE=true ./build.sh
```

### 构建前验证

运行构建环境验证以确保构建成功：

```bash
./validate-build.sh
```

该脚本将检查：
- Docker 安装和状态
- 网络连接
- 包仓库可用性
- 磁盘空间
- Git 仓库访问

### 本地测试脚本

构建完成后，可以使用测试脚本验证镜像：

```bash
./test-build.sh
```

该脚本会自动构建镜像并运行全面测试。

## 技术细节

### 构建流程

1. **多阶段构建**: 使用 Alpine Linux 3.20 作为构建环境，分离构建和运行时环境
2. **依赖管理**: 自动安装 KCPTube 所需的运行时依赖，支持多镜像源
3. **安全性**: 使用非特权用户运行容器
4. **多架构支持**: 支持 AMD64 和 ARM64 架构
5. **构建优化**: 包含 .dockerignore 和构建缓存优化
6. **错误处理**: 改进的构建错误处理和诊断

### 自动化构建

GitHub Actions 会在以下情况自动构建并推送镜像：
- 推送到 `main` 或 `master` 分支
- 创建新的标签（版本发布）
- 提交 Pull Request（仅构建测试，不推送）
- 手动触发构建（支持强制重新构建选项）

构建的镜像会自动推送到 GitHub Container Registry：`ghcr.io/thisdk/kcptube`

新版本包含以下改进：
- 安全扫描和漏洞检测
- 构建证明和供应链安全
- 改进的错误处理和重试机制
- Pull Request 构建测试

## 许可证

本项目基于 Apache License 2.0 许可证。原 KCPTube 项目的许可证请参考 [cnbatch/kcptube](https://github.com/cnbatch/kcptube)。

## 相关项目

- [cnbatch/kcptube](https://github.com/cnbatch/kcptube) - 原始项目
- [cnbatch/udphop](https://github.com/cnbatch/udphop) - UDP 转发工具
