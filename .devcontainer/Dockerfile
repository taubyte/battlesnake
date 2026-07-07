# Optional local build — Codespaces uses devcontainer.json "image" + features instead.
# This Dockerfile is kept for local `devcontainer build` testing only.
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ARG TAU_CLI_VERSION=0.1.16
ENV TAU_CLI_VERSION=${TAU_CLI_VERSION}

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl jq rsync ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

COPY install-tools.sh /tmp/install-tools.sh
RUN chmod +x /tmp/install-tools.sh && bash /tmp/install-tools.sh
