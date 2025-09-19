# Multi-stage build for kcptube
FROM alpine:3.20 AS builder

# Install essential build dependencies including Python for Botan
RUN apk add --no-cache \
        build-base \
        cmake \
        git \
        python3 \
        asio-dev \
        pkgconfig \
    && rm -rf /var/cache/apk/*

# Build and install Botan 3 from source (minimal build)
RUN cd /tmp && \
    git clone --depth 1 --branch 3.6.1 https://github.com/randombit/botan.git && \
    cd botan && \
    python3 configure.py --minimized-build --enable-modules=aead,aes,gcm,ocb,chacha20poly1305,sha3,crc32 --disable-shared --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    ln -sf /usr/local/include/botan-3/botan /usr/local/include/botan && \
    cd / && rm -rf /tmp/botan

# Create working directory
WORKDIR /app

# Clone the original kcptube source code
RUN git clone https://github.com/cnbatch/kcptube.git . && \
    git submodule update --init --recursive

# Build the application with error handling
RUN mkdir build && \
    cd build && \
    PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH" \
    cmake -DCMAKE_PREFIX_PATH=/usr/local .. && \
    make -j$(nproc) && \
    ls -la kcptube && \
    file kcptube && \
    ldd kcptube || true

# Runtime stage
FROM alpine:3.20

# Install minimal runtime dependencies
RUN apk add --no-cache \
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

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/kcptube /dev/null 2>&1 && exit 0 || exit 1

# Default command
ENTRYPOINT ["/usr/local/bin/kcptube"]
CMD ["--help"]
