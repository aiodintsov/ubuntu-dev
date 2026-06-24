FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Bootstrap: tools needed to add third-party apt repos
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Ubuntu 26.04 base image already has an 'ubuntu' user at UID/GID 1000
# Alias it as 'vscode' for devcontainer compatibility
RUN usermod -l vscode ubuntu \
    && usermod -d /home/vscode -m vscode \
    && groupmod -n vscode ubuntu

# Register third-party apt repos: NodeSource, GitHub CLI, MongoDB, Docker, Azure CLI
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc \
        | gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" \
        > /etc/apt/sources.list.d/mongodb-org-8.0.list \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        > /etc/apt/sources.list.d/docker.list \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ noble main" \
        > /etc/apt/sources.list.d/azure-cli.list

# Install all apt packages in one layer
RUN apt-get update && apt-get install -y \
    # Node.js (latest via NodeSource)
    nodejs \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    # GitHub CLI
    gh \
    # MongoDB Shell
    mongodb-mongosh \
    # Java
    default-jdk-headless \
    # network
    wget \
    dnsutils \
    iputils-ping \
    traceroute \
    nmap \
    netcat-openbsd \
    socat \
    net-tools \
    iproute2 \
    openssh-client \
    httpie \
    # XML / INI / data
    jq \
    xmlstarlet \
    libxml2-utils \
    crudini \
    # Docker CLI (daemon runs on the host via socket mount)
    docker-ce-cli \
    docker-compose-plugin \
    # Azure CLI
    azure-cli \
    # general utilities
    git \
    sudo \
    vim \
    nano \
    less \
    zip \
    unzip \
    tar \
    watch \
    tree \
    htop \
    default-mysql-client \
    && ln -sf /usr/bin/python3 /usr/local/bin/python \
    && rm -rf /var/lib/apt/lists/*

# sqlcmd (go-sqlcmd binary — avoids apt repo package name changes)
RUN curl -fsSL "https://github.com/microsoft/go-sqlcmd/releases/latest/download/sqlcmd-linux-amd64.tar.bz2" \
        | tar -xj -C /usr/local/bin sqlcmd \
    && chmod +x /usr/local/bin/sqlcmd

# yq (YAML/JSON/XML/TOML/CSV processor — binary release)
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(dpkg --print-architecture)" \
        -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# AWS CLI (official bundled installer — handles amd64 and arm64)
RUN ARCH=$(dpkg --print-architecture | sed 's/amd64/x86_64/;s/arm64/aarch64/') \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws

# Fly CLI
RUN curl -fsSL https://fly.io/install.sh | FLYCTL_INSTALL=/usr/local sh

# Wrangler CLI (Cloudflare — npm global, Node.js already installed)
RUN npm install -g wrangler

# Terraform toolchain: tfenv + latest Terraform + tflint
RUN git clone --depth=1 https://github.com/tfutils/tfenv.git /usr/local/tfenv \
    && ln -s /usr/local/tfenv/bin/tfenv /usr/local/bin/tfenv \
    && ln -s /usr/local/tfenv/bin/terraform /usr/local/bin/terraform \
    && tfenv install latest \
    && tfenv use latest \
    && curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Allow vscode user to use sudo without a password; add to docker group for socket access
RUN echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode \
    && groupadd -f docker \
    && usermod -aG docker vscode

# .NET (latest LTS via install script — avoids apt repo lag on new Ubuntu releases)
ENV DOTNET_ROOT=/usr/local/dotnet
ENV PATH=$PATH:/usr/local/dotnet
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- \
    --channel LTS \
    --install-dir /usr/local/dotnet \
    && chmod -R a+rx /usr/local/dotnet

USER vscode
WORKDIR /home/vscode

CMD ["/bin/bash"]
