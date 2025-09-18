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

如需自行构建镜像：

```bash
git clone https://github.com/thisdk/kcptube.git
cd kcptube
docker build -t my-kcptube .
```

## 许可证

本项目基于 Apache License 2.0 许可证。原 KCPTube 项目的许可证请参考 [cnbatch/kcptube](https://github.com/cnbatch/kcptube)。

## 相关项目

- [cnbatch/kcptube](https://github.com/cnbatch/kcptube) - 原始项目
- [cnbatch/udphop](https://github.com/cnbatch/udphop) - UDP 转发工具
