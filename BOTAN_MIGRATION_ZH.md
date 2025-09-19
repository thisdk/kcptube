# Botan 3 动态链接迁移说明

## 问题描述
原始工程中 Botan 3 加密库是通过源码编译成静态库的方式链接。用户希望改为使用动态链接形式。

## 解决方案

### 原始配置 (静态链接)
```dockerfile
# 从源码编译 Botan（静态库）
python3 configure.py --minimized-build --enable-modules=... --disable-shared --prefix=/usr/local
```

### 新配置 (动态链接)
```dockerfile
# 从源码编译 Botan（动态库）  
python3 configure.py --enable-shared --enable-modules=... --prefix=/usr/local
```

## 主要变更

### 1. 构建阶段变更
- **移除**: `--disable-shared` 和 `--minimized-build` 参数
- **添加**: `--enable-shared` 参数以生成动态库
- **保持**: 相同的加密模块支持 (aead,aes,gcm,ocb,chacha20poly1305,sha3,crc32)

### 2. 运行时阶段变更
- **添加**: 将构建阶段的 Botan 动态库 (`libbotan*.so*`) 复制到运行时镜像
- **添加**: `ldconfig` 命令来注册动态库路径
- **移除**: 对不存在的 `botan3-libs` APK 包的依赖

### 3. 链接配置优化
- **环境变量**: 添加 `PKG_CONFIG_PATH` 和 `LD_LIBRARY_PATH` 
- **CMake 配置**: 保持 `CMAKE_PREFIX_PATH` 指向 `/usr/local`

## 效果对比

| 方面 | 静态链接 (之前) | 动态链接 (现在) |
|------|----------------|----------------|
| 二进制大小 | 较大 (包含库代码) | 较小 (仅引用库) |
| 内存使用 | 每个进程独占库内存 | 多进程共享库内存 |
| 安全更新 | 需要重编译整个程序 | 可独立更新库文件 |
| 部署复杂度 | 较简单 (单文件) | 需要管理库依赖 |
| 启动性能 | 稍快 (无动态加载) | 稍慢 (需动态加载) |

## 技术细节

### Dockerfile 关键变更
```dockerfile
# 构建阶段：生成动态库
RUN cd /tmp && \
    git clone --depth 1 --branch 3.6.1 https://github.com/randombit/botan.git && \
    cd botan && \
    python3 configure.py \
        --enable-shared \
        --enable-modules=aead,aes,gcm,ocb,chacha20poly1305,sha3,crc32 \
        --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    ldconfig /usr/local/lib

# 运行时阶段：复制动态库
COPY --from=builder /usr/local/lib/libbotan*.so* /usr/local/lib/
RUN ldconfig /usr/local/lib
```

## 验证方法

构建完成后可通过以下命令验证动态链接：
```bash
# 检查动态库依赖
docker run --rm kcptube ldd /usr/local/bin/kcptube

# 期望输出包含类似:
# libbotan-3.so.3 => /usr/local/lib/libbotan-3.so.3.6.1

# 检查库文件存在
docker run --rm kcptube ls -la /usr/local/lib/libbotan*
```

## 注意事项

1. **Alpine 包可用性**: 经验证，Alpine Linux 3.20 中暂未提供 `botan3-libs` 包，因此仍需从源码编译
2. **兼容性**: 动态链接版本与原静态链接版本功能完全一致
3. **性能影响**: 动态链接对性能的影响微乎其微，且获得了更好的内存效率