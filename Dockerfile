# Multi-stage build for kcptube
FROM alpine:3.20 AS builder

# Install essential build dependencies and Botan 3 packages
RUN apk add --no-cache git build-base cmake asio-dev botan3-dev && rm -rf /var/cache/apk/* \
    && ln -sf /usr/include/botan-3 /usr/include/botan \
    && apk info -L botan3-dev | grep include \
    && find /usr -name "*cipher_mode*" 2>/dev/null

# Create working directory
WORKDIR /app

# Clone the original kcptube source code
RUN git clone https://github.com/cnbatch/kcptube.git .

# Build the application with dynamic Botan linking
RUN mkdir build && cd build && cmake .. && make -j$(nproc) && ls -la kcptube && file kcptube && ldd kcptube || true

# Runtime stage
FROM alpine:3.20

# Install runtime dependencies including Botan 3 libraries
RUN apk add --no-cache tzdata botan3-libs && rm -rf /var/cache/apk/*

# Create non-root user
RUN addgroup -g 1000 kcptube && adduser -D -s /bin/sh -u 1000 -G kcptube kcptube

# Copy binary from builder stage
COPY --from=builder /app/build/kcptube /usr/local/bin/kcptube

# Set proper permissions
RUN chmod +x /usr/local/bin/kcptube

# Create config directory
RUN mkdir -p /etc/kcptube && chown -R kcptube:kcptube /etc/kcptube

# Switch to non-root user
USER kcptube

# Set working directory
WORKDIR /etc/kcptube

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 CMD /usr/local/bin/kcptube /dev/null 2>&1 && exit 0 || exit 1

# Default command
ENTRYPOINT ["/usr/local/bin/kcptube"]

CMD ["--help"]
