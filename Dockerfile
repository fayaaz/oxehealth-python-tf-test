FROM ghcr.io/opentofu/opentofu:1.9-minimal AS tofu

FROM python:3.12-bookworm

# Copy the tofu binary
COPY --from=tofu /usr/local/bin/tofu /usr/local/bin/tofu

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENTRYPOINT ["/usr/local/bin/tofu"]
