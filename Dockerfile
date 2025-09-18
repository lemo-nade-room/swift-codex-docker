FROM ubuntu:noble

SHELL ["/bin/bash", "-c"]

# ================================
# apt
# ================================
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && \
    apt update && \
    apt install -y --no-install-recommends \
    ca-certificates \
    curl \
    sudo \
    build-essential \
    make \
    locales \
    unzip \
    git \
    libncurses6 \
    libncurses-dev \
    binutils \
    gnupg2 \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-13-dev \
    libpython3-dev \
    libsqlite3-0 \
    libstdc++-13-dev \
    libxml2-dev \
    libz3-dev \
    pkg-config \
    tzdata \
    zlib1g-dev \
    openssl \
    libssl-dev \
    inotify-tools \
    jq \
    uidmap \
    kmod \
    iptables \
    docker.io \
    docker-compose-v2 \
    socat \
    screen \
    docker-buildx \
    openssh-client

# ================================
# User
# ================================
RUN echo 'lemo ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/lemo
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /lemo lemo
RUN usermod -aG docker lemo
USER lemo:lemo
WORKDIR /lemo

# ================================
# Docker
# ================================
ENV DOCKER_HOST="unix:///var/run/docker.sock"

# ================================
# GitHub gh
# ================================
RUN (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y --no-install-recommends)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
	&& sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y --no-install-recommends

# ================================
# Open Tofu
# ================================
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
RUN chmod +x install-opentofu.sh
RUN ./install-opentofu.sh --install-method deb
RUN rm -f install-opentofu.sh

# ================================
# Setup Swift
# ================================
WORKDIR /swiftly
RUN NONINTERACTIVE=1 curl -O "https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz" && \
    tar zxf "swiftly-$(uname -m).tar.gz" && \
    ./swiftly init --quiet-shell-followup && \
    . ${SWIFTLY_HOME_DIR:-~/.local/share/swiftly}/env.sh && \
    hash -r && \
    echo "source ${SWIFTLY_HOME_DIR:-~/.local/share/swiftly}/env.sh" >> /lemo/.bashrc && \
    rm -f "swiftly-$(uname -m).tar.gz"

# ================================
# Homebrew
# ================================
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
RUN echo >> /lemo/.bashrc
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /lemo/.bashrc
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
RUN brew install \
    awscli \
    aws-sam-cli \
    cloudflare-wrangler \
    codex \
    deno \
    direnv \
    git \
    node \
    oven-sh/bun/bun \
    swift-format \
    swift-protobuf \
    tree \
    uv \
    xh \
    && brew cleanup -s && rm -rf $(brew --cache)

# ================================
# Setup Direnv
# ================================
RUN echo 'eval "$(direnv hook bash)"' >> ~/.bashrc

# ================================
# AWS MCP
# ================================
RUN uv python install 3.10

# ================================
# PATH
# ================================
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# ================================
# Cleanup build dependencies
# ================================
RUN sudo apt-get purge -y \
    build-essential \
    make \
    && sudo apt-get autoremove --purge -y \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /lemo/workspace

# ================================
# Permission
# ================================
RUN sudo chown -R lemo:lemo /swiftly
RUN sudo chown -R lemo:lemo /lemo/workspace

CMD ["/bin/bash"]