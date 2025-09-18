# Multi-stage build for kcptube
FROM alpine:3.20 AS builder

# Configure Alpine repositories and install build dependencies
RUN echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/main" > /etc/apk/repositories && \
    echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/community" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.20/main" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.20/community" >> /etc/apk/repositories && \
    apk update --no-cache && \
    apk add --no-cache \
        build-base \
        cmake \
        git \
        asio-dev \
        botan-dev \
        linux-headers \
        pkgconfig

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

# Configure Alpine repositories and install runtime dependencies
RUN echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/main" > /etc/apk/repositories && \
    echo "https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.20/community" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.20/main" >> /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.20/community" >> /etc/apk/repositories && \
    apk update --no-cache && \
    apk add --no-cache \
        botan-libs \
        libgcc \
        libstdc++

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

# Default command
ENTRYPOINT ["/usr/local/bin/kcptube"]
CMD ["--help"]