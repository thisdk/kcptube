# Multi-stage build for kcptube
FROM alpine:3.20 AS builder

# Configure Alpine repositories with fallbacks and install build dependencies
RUN set -ex && \
    # Backup original repos
    cp /etc/apk/repositories /etc/apk/repositories.backup && \
    # Try multiple mirror sources
    { \
        echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/main" > /etc/apk/repositories && \
        echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/community" >> /etc/apk/repositories && \
        timeout 30 apk update --no-cache; \
    } || { \
        echo "Primary mirror failed, trying Alibaba mirror..." && \
        echo "https://mirrors.aliyun.com/alpine/v3.20/main" > /etc/apk/repositories && \
        echo "https://mirrors.aliyun.com/alpine/v3.20/community" >> /etc/apk/repositories && \
        timeout 30 apk update --no-cache; \
    } || { \
        echo "Alibaba mirror failed, using official repositories..." && \
        cp /etc/apk/repositories.backup /etc/apk/repositories && \
        timeout 60 apk update --no-cache; \
    } && \
    apk add --no-cache \
        build-base \
        cmake \
        git \
        asio-dev \
        botan-dev \
        linux-headers \
        pkgconfig \
    && rm -rf /var/cache/apk/*

# Create working directory
WORKDIR /app

# Clone the original kcptube source code
RUN git clone https://github.com/cnbatch/kcptube.git . && \
    git submodule update --init --recursive

# Build the application with error handling
RUN mkdir build && \
    cd build && \
    cmake .. && \
    make -j$(nproc) && \
    ls -la kcptube && \
    file kcptube && \
    ldd kcptube || true

# Runtime stage
FROM alpine:3.20

# Configure Alpine repositories with fallbacks and install runtime dependencies
RUN set -ex && \
    # Backup original repos
    cp /etc/apk/repositories /etc/apk/repositories.backup && \
    # Try multiple mirror sources
    { \
        echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/main" > /etc/apk/repositories && \
        echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/community" >> /etc/apk/repositories && \
        timeout 30 apk update --no-cache; \
    } || { \
        echo "Primary mirror failed, trying Alibaba mirror..." && \
        echo "https://mirrors.aliyun.com/alpine/v3.20/main" > /etc/apk/repositories && \
        echo "https://mirrors.aliyun.com/alpine/v3.20/community" >> /etc/apk/repositories && \
        timeout 30 apk update --no-cache; \
    } || { \
        echo "Alibaba mirror failed, using official repositories..." && \
        cp /etc/apk/repositories.backup /etc/apk/repositories && \
        timeout 60 apk update --no-cache; \
    } && \
    apk add --no-cache \
        botan-libs \
        libgcc \
        libstdc++ \
    && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1000 kcptube && \
    adduser -D -s /bin/sh -u 1000 -G kcptube kcptube

# Copy binary from builder stage
COPY --from=builder /app/build/kcptube /usr/local/bin/kcptube

# Set proper permissions
RUN chmod +x /usr/local/bin/kcptube

# Create config directory
RUN mkdir -p /etc/kcptube && \
    chown -R kcptube:kcptube /etc/kcptube

# Switch to non-root user
USER kcptube

# Set working directory
WORKDIR /etc/kcptube

# Expose common ports (can be overridden)
EXPOSE 3000-4000/udp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/kcptube --help > /dev/null || exit 1

# Default command
ENTRYPOINT ["/usr/local/bin/kcptube"]
CMD ["--help"]