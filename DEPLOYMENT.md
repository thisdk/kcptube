# KCPTube 部署指南

## 快速部署

### 1. 单容器部署

#### 客户端部署
```bash
# 创建配置文件
mkdir -p ~/kcptube
cat > ~/kcptube/client.conf << 'EOF'
mode=client
kcp=regular3
inbound_bandwidth=500M
outbound_bandwidth=50M
listen_port=59000
destination_port=3000
destination_address=YOUR_SERVER_IP
encryption_password=your_password
encryption_algorithm=AES-GCM
EOF

# 运行客户端
docker run -d \
  --name kcptube-client \
  --restart unless-stopped \
  -p 59000:59000/udp \
  -v ~/kcptube/client.conf:/etc/kcptube/config.conf:ro \
  ghcr.io/thisdk/kcptube:latest \
  /etc/kcptube/config.conf
```

#### 服务端部署
```bash
# 创建配置目录
mkdir -p ~/kcptube/logs

# 创建服务端配置
cat > ~/kcptube/server.conf << 'EOF'
mode=server
kcp=regular3
inbound_bandwidth=1G
outbound_bandwidth=1G
listen_port=3000-4000
destination_port=59000
destination_address=::1
encryption_password=your_password
encryption_algorithm=AES-GCM
stun_server=stun.qq.com
log_path=/var/log/kcptube/
EOF

# 运行服务端
docker run -d \
  --name kcptube-server \
  --restart unless-stopped \
  -p 3000-4000:3000-4000/udp \
  -v ~/kcptube/server.conf:/etc/kcptube/config.conf:ro \
  -v ~/kcptube/logs:/var/log/kcptube \
  ghcr.io/thisdk/kcptube:latest \
  /etc/kcptube/config.conf
```

### 2. Docker Compose 部署

创建 `docker-compose.yml`:

```yaml
version: '3.8'

services:
  kcptube-server:
    image: ghcr.io/thisdk/kcptube:latest
    container_name: kcptube-server
    restart: unless-stopped
    ports:
      - "3000-4000:3000-4000/udp"
    volumes:
      - ./server.conf:/etc/kcptube/config.conf:ro
      - ./logs:/var/log/kcptube
    environment:
      - TZ=Asia/Shanghai
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  kcptube-client:
    image: ghcr.io/thisdk/kcptube:latest
    container_name: kcptube-client
    restart: unless-stopped
    ports:
      - "59000:59000/udp"
    volumes:
      - ./client.conf:/etc/kcptube/config.conf:ro
    environment:
      - TZ=Asia/Shanghai
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    depends_on:
      - kcptube-server
```

运行:
```bash
docker-compose up -d
```

## 高级配置

### 性能优化

对于高带宽环境：
```ini
mode=server
kcp=fast2
inbound_bandwidth=10G
outbound_bandwidth=10G
blast=true
kcp_sndwnd=4096
kcp_rcvwnd=4096
```

对于高延迟环境：
```ini
mode=client
kcp=regular1
udp_timeout=300
keep_alive=60
dport_refresh=300
```

### 安全配置

使用强加密：
```ini
encryption_algorithm=chacha20
encryption_password=very_strong_password_with_special_chars!@#
```

### 多路复用

客户端启用多路复用（适合代理场景）：
```ini
mode=client
mux_tunnels=5
```

## 监控和维护

### 日志查看
```bash
# 查看容器日志
docker logs kcptube-server
docker logs -f kcptube-client

# 查看应用日志（如果配置了 log_path）
tail -f ~/kcptube/logs/kcptube.log
```

### 健康检查
```bash
# 检查容器状态
docker ps | grep kcptube

# 检查端口占用
netstat -ulnp | grep :3000
netstat -ulnp | grep :59000

# 测试配置
docker run --rm \
  -v ~/kcptube/client.conf:/etc/kcptube/config.conf:ro \
  ghcr.io/thisdk/kcptube:latest \
  --check-config /etc/kcptube/config.conf
```

### 更新镜像
```bash
# 拉取最新镜像
docker pull ghcr.io/thisdk/kcptube:latest

# 重新创建容器
docker-compose down
docker-compose up -d

# 或者
docker stop kcptube-server kcptube-client
docker rm kcptube-server kcptube-client
# 然后重新运行 docker run 命令
```

## 故障排查

使用提供的故障排查脚本：
```bash
curl -sSL https://raw.githubusercontent.com/thisdk/kcptube/main/troubleshoot.sh | bash
```

或者下载后运行：
```bash
wget https://raw.githubusercontent.com/thisdk/kcptube/main/troubleshoot.sh
chmod +x troubleshoot.sh
./troubleshoot.sh
```

## 防火墙配置

### UFW (Ubuntu)
```bash
sudo ufw allow 3000:4000/udp
sudo ufw allow 59000/udp
```

### Firewalld (CentOS/RHEL)
```bash
sudo firewall-cmd --add-port=3000-4000/udp --permanent
sudo firewall-cmd --add-port=59000/udp --permanent
sudo firewall-cmd --reload
```

### Iptables
```bash
iptables -A INPUT -p udp --dport 3000:4000 -j ACCEPT
iptables -A INPUT -p udp --dport 59000 -j ACCEPT
```