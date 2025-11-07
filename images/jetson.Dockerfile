# Jetson-specific Dockerfile using L4T ML runtime
# Based on NVIDIA L4T ML container

FROM nvcr.io/nvidia/l4t-ml:r36.2.0-py3

# Set working directory
WORKDIR /workspace

# Install additional Python packages if needed
RUN pip3 install --no-cache-dir --upgrade pip

# Copy entrypoint script
COPY images/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set environment variables for Jetson
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command (can be overridden)
CMD ["python3", "-m", "http.server", "8000"]

