# Multi-arch base Dockerfile for crossplay
# Supports linux/amd64 and linux/arm64

ARG TARGETPLATFORM
ARG BUILDPLATFORM

FROM python:3.11-slim

# Set working directory
WORKDIR /workspace

# Install system dependencies based on platform
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            build-essential \
            curl \
            && rm -rf /var/lib/apt/lists/*; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends \
            build-essential \
            curl \
            && rm -rf /var/lib/apt/lists/*; \
    fi

# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /workspace

# Copy entrypoint script
COPY images/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Switch to non-root user
USER appuser

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command (can be overridden)
CMD ["python", "-m", "http.server", "8000"]

