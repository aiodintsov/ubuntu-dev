FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

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

# Node.js (latest via NodeSource)
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Python (latest available in Ubuntu repos)
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && ln -sf /usr/bin/python3 /usr/local/bin/python \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# mongosh (MongoDB Shell)
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc \
        | gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" \
        > /etc/apt/sources.list.d/mongodb-org-8.0.list \
    && apt-get update && apt-get install -y mongodb-mongosh \
    && rm -rf /var/lib/apt/lists/*

# sqlcmd (go-sqlcmd binary — avoids apt repo package name changes)
RUN curl -fsSL "https://github.com/microsoft/go-sqlcmd/releases/latest/download/sqlcmd-linux-amd64.tar.bz2" \
        | tar -xj -C /usr/local/bin sqlcmd \
    && chmod +x /usr/local/bin/sqlcmd

# Network, data-processing, and general dev tools
RUN apt-get update && apt-get install -y \
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
    && rm -rf /var/lib/apt/lists/*

# yq (YAML/JSON/XML/TOML/CSV processor — binary release)
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(dpkg --print-architecture)" \
        -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Allow vscode user to use sudo without a password
RUN echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

# OpenJDK (latest available in Ubuntu repos)
RUN apt-get update && apt-get install -y \
    default-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

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
