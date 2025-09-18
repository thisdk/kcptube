# KCPTube 构建快速参考

## 🚀 快速开始

```bash
# 1. 克隆仓库
git clone https://github.com/thisdk/kcptube.git
cd kcptube

# 2. 验证构建环境
./validate-build.sh

# 3. 构建镜像
./build.sh

# 4. 测试镜像
./test-build.sh
```

## 🛠️ 构建选项

### 基础构建
```bash
./build.sh                    # 自动策略
./test-build.sh              # 简单构建+测试
docker build -t my-kcptube . # 直接 Docker 构建
```

### 高级构建
```bash
BUILD_STRATEGY=fast ./build.sh     # 快速构建
BUILD_STRATEGY=safe ./build.sh     # 安全构建
BUILD_STRATEGY=debug ./build.sh    # 调试构建
NO_CACHE=true ./build.sh          # 无缓存构建
```

### 自定义镜像名
```bash
./build.sh my-custom-name          # 指定镜像名
BUILD_STRATEGY=fast ./build.sh my-kcptube
```

## 🔍 诊断工具

```bash
./validate-build.sh           # 构建前验证
./troubleshoot.sh            # 运行时故障排查
docker logs kcptube          # 查看容器日志
```

## 📋 构建策略说明

| 策略 | 说明 | 使用场景 |
|------|------|----------|
| `auto` | 自动选择，平衡速度和可靠性 | 日常使用 |
| `fast` | 快速构建，使用缓存 | 开发调试 |
| `safe` | 安全构建，无缓存，详细输出 | 生产环境 |
| `debug` | 调试模式，最详细输出 | 问题排查 |

## 🚨 常见问题

### 网络问题
```bash
# 检查连接
ping -c 3 mirrors.tuna.tsinghua.edu.cn
ping -c 3 dl-cdn.alpinelinux.org

# 使用调试模式
BUILD_STRATEGY=debug ./build.sh
```

### 磁盘空间不足
```bash
# 清理 Docker
docker system prune -f
docker builder prune -f

# 检查空间
df -h
```

### 包依赖问题
```bash
# 验证包可用性
./validate-build.sh

# 手动测试包安装
docker run --rm alpine:3.20 sh -c "apk update && apk search botan-dev"
```

## 🔄 CI/CD 集成

### GitHub Actions
- 推送到 `main` 分支自动构建
- 创建标签自动发布
- PR 自动测试构建
- 手动触发支持强制重建

### 本地模拟 CI 构建
```bash
# 模拟 CI 环境构建
NO_CACHE=true BUILD_STRATEGY=safe ./build.sh ghcr.io/thisdk/kcptube:test
```

## 📦 使用构建的镜像

```bash
# 基本使用
docker run --rm kcptube-local --help

# 客户端配置
docker run -d \
  --name kcptube-client \
  -p 59000:59000/udp \
  -v ./config.conf:/etc/kcptube/config.conf:ro \
  kcptube-local /etc/kcptube/config.conf

# 服务端配置
docker run -d \
  --name kcptube-server \
  -p 3000-4000:3000-4000/udp \
  -v ./server.conf:/etc/kcptube/config.conf:ro \
  kcptube-local /etc/kcptube/config.conf
```

## 🛟 获得帮助

1. 查看脚本帮助: `./build.sh --help`
2. 运行诊断工具: `./troubleshoot.sh`
3. 查看详细日志: `BUILD_STRATEGY=debug ./build.sh`
4. 访问项目主页: https://github.com/thisdk/kcptube