# Dev Container for Emissary Development
FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install base system packages and missing utils
# Base development tools:
#   build-essential, curl, wget, git, unzip, ca-certificates, gnupg,
#   lsb-release, software-properties-common
# Archive tools:
#   libarchive-tools
# Missing utils for nektos/act:
#   rsync, iproute2, net-tools
# Additional useful dev tools:
#   jq, vim, nano, htop, tree
RUN apt-get update -y && apt-get install -y \
    build-essential \
    curl \
    wget \
    git \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    libarchive-tools \
    rsync \
    iproute2 \
    net-tools \
    jq \
    vim \
    nano \
    htop \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN ARCH="$(uname -m | sed 's#x86_64#amd64#g; s#aarch64#arm64#g')" && \
    OS="$(uname -s | tr '[[:upper:]]' '[[:lower:]]')" && \
    curl -fsSL -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/cli/cli/releases/latest | \
    jq -r ".assets[] | select(.name | test(\"gh_.*_linux_${ARCH}.tar.gz\")) | .browser_download_url" | \
    xargs curl -fsSL | tar --strip-components=1 -C /usr/local/bin --wildcards -xz '*/bin/gh'

# Install Docker (for k3d and other container operations)
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | \
    tee /etc/apt/sources.list.d/kubernetes.list && \
    apt-get update && \
    apt-get install -y kubectl && \
    rm -rf /var/lib/apt/lists/*

# Install k3d
RUN curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Install Helm and plugins
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    helm plugin install https://github.com/chartmuseum/helm-push

# Install Go (determine version from build arg)
ARG GO_MOD_VERSION=1.24
RUN echo "Go version from go.mod: ${GO_MOD_VERSION}" && \
    # Check if this is a two-part version (e.g., 1.21)
    if echo "${GO_MOD_VERSION}" | grep -qE '^[0-9]+\.[0-9]+$'; then \
    echo "Two-part version detected: ${GO_MOD_VERSION}" && \
    # For newer versions (1.23+), try to get the latest patch version from API
    if echo "${GO_MOD_VERSION}" | grep -qE '^1\.(2[3-9]|[3-9][0-9])$'; then \
    echo "Recent version, checking API for latest patch..." && \
    GO_DOWNLOAD_VERSION=$(curl -s "https://go.dev/dl/?mode=json" | \
    jq -r --arg version "${GO_MOD_VERSION}" \
    '[.[] | select(.version | startswith("go" + $version + ".")) | .version] | sort_by(. | ltrimstr("go") | split(".") | map(tonumber)) | last | ltrimstr("go")'); \
    if [ -z "${GO_DOWNLOAD_VERSION}" ] || [ "${GO_DOWNLOAD_VERSION}" = "null" ]; then \
    echo "No patch version found in API, using .0" && \
    GO_DOWNLOAD_VERSION="${GO_MOD_VERSION}.0"; \
    fi; \
    else \
    echo "Older version, using .0 patch version" && \
    GO_DOWNLOAD_VERSION="${GO_MOD_VERSION}.0"; \
    fi; \
    else \
    echo "Using exact version: ${GO_MOD_VERSION}" && \
    GO_DOWNLOAD_VERSION="${GO_MOD_VERSION}"; \
    fi && \
    echo "Downloading Go version: ${GO_DOWNLOAD_VERSION}" && \
    curl -fsSL https://go.dev/dl/go${GO_DOWNLOAD_VERSION}.linux-$(dpkg --print-architecture).tar.gz | \
    tar -C /usr/local -xz
ENV PATH=/usr/local/go/bin:${PATH}
ENV GOPATH=/go
ENV GOBIN=${GOPATH}/bin
ENV PATH=${GOBIN}:${PATH}

# Install uv (Python package manager) into /usr/local/bin
RUN curl -LsSf https://astral.sh/uv/install.sh | XDG_BIN_HOME=/usr/local/bin bash

# Install Python and common tools
RUN uv python install 3.12 && \
    uv tool install awscli

# Install common Go tools for development
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Install protoc
RUN ARCH="$(uname -m | sed 's#x86_64#x86_64#g; s#aarch64#aarch_64#g')" && \
    curl -fsSL -o protoc.zip "https://github.com/protocolbuffers/protobuf/releases/latest/download/protoc-$(curl -s https://api.github.com/repos/protocolbuffers/protobuf/releases/latest | jq -r .tag_name | sed 's/v//')-linux-${ARCH}.zip" && \
    unzip -q protoc.zip -d /usr/local && \
    rm protoc.zip

# Ubuntu already has a user `ubuntu` at UID/GID 1000, so let's just use that.
ARG USERNAME=ubuntu
# ARG USER_UID=1000
# ARG USER_GID=${USER_UID}
# RUN if ! getent group ${USER_GID} >/dev/null 2>&1; then \
#     groupadd --gid ${USER_GID} ${USERNAME}; \
#     fi && \
#     if ! getent passwd ${USER_UID} >/dev/null 2>&1; then \
#     useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash; \
#     fi && \
#     echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up Go workspace for the dev user
# NOTE: These ENV commands must be placed before the USER instruction below,
# because ARG variables are not available in ENV instructions after USER changes context
ENV GOPATH=/home/${USERNAME}/go
ENV GOBIN=${GOPATH}/bin
ENV PATH=${GOBIN}:${PATH}

# Switch to non-root user
USER ${USERNAME}

# Set up shell environment
RUN echo 'export GOPATH="/home/${USERNAME}/go"' >> /home/${USERNAME}/.bashrc && \
    echo 'export GOBIN="${GOPATH}/bin"' >> /home/${USERNAME}/.bashrc && \
    echo 'export PATH="${GOBIN}:${PATH}"' >> /home/${USERNAME}/.bashrc

WORKDIR /emissary

# Default command
CMD ["/bin/bash"]
