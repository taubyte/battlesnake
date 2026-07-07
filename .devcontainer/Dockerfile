FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG TAU_CLI_VERSION=0.1.16

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    rsync \
    ca-certificates \
    git \
    && rm -rf /var/lib/apt/lists/*

# tau CLI binary
RUN ARCH="$(uname -m)" \
    && case "$ARCH" in \
      x86_64) BIN_ARCH=amd64 ;; \
      aarch64|arm64) BIN_ARCH=arm64 ;; \
      *) echo "unsupported arch: $ARCH" >&2; exit 1 ;; \
    esac \
    && curl -fsSL \
      "https://github.com/taubyte/tau-cli/releases/download/v${TAU_CLI_VERSION}/tau-cli_${TAU_CLI_VERSION}_linux_${BIN_ARCH}.tar.gz" \
      -o /tmp/tau-cli.tar.gz \
    && tar -xzf /tmp/tau-cli.tar.gz -C /usr/local/bin tau \
    && rm /tmp/tau-cli.tar.gz \
    && chmod 755 /usr/local/bin/tau

# Node.js (for taubyte/skills install) + dream CLI
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://get.tau.link/dream | sh \
    && command -v dream
