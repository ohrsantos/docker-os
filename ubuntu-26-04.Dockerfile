FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TERRAFORM_VERSION=1.15.8
ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=v24.5.0
ARG TARGETARCH

RUN apt update &&                                                                                  \
    apt install -y --no-install-recommends                                                         \
        apt-transport-https                                                                        \
        awscli                                                                                     \
        build-essential                                                                            \
        ca-certificates                                                                            \
        cmake                                                                                      \
        csvkit                                                                                     \
        curl                                                                                       \
        dnsutils                                                                                   \
        fzf                                                                                        \
        gettext                                                                                    \
        git                                                                                        \
        gzip                                                                                       \
        htop                                                                                       \
        iproute2                                                                                   \
        iputils-ping                                                                               \
        jq                                                                                         \
        ksh                                                                                        \
        less                                                                                       \
        locales                                                                                    \
        net-tools                                                                                  \
        ninja-build                                                                                \
        openjdk-21-jre-headless                                                                    \
        openssh-client                                                                             \
        pre-commit                                                                                 \
        procps                                                                                     \
        pv                                                                                         \
        python3                                                                                    \
        python3-pip                                                                                \
        python3-pygments                                                                           \
        ranger                                                                                     \
        software-properties-common                                                                 \
        sudo                                                                                       \
        tar                                                                                        \
        tree                                                                                       \
        tzdata                                                                                     \
        unzip                                                                                      \
        vim                                                                                        \
        wget                                                                                       \
        xz-utils                                                                                   \
        zip                                                                                        \
        zoxide                                                                                     \
        zsh-syntax-highlighting                                                                    \
        zsh                                                                                        \
        &&                                                                                         \
    mkdir -p /opt && \
    cd /opt && \
    wget https://archive.apache.org/dist/kafka/4.3.1/kafka_2.13-4.3.1.tgz && \
    tar xzf kafka_2.13-4.3.1.tgz && \
    rm -f kafka_2.13-4.3.1.tgz && \
    cd /tmp && \
    TERRAFORM_ARCH="${TARGETARCH:-}" && \
    if [ -z "$TERRAFORM_ARCH" ]; then \
        DEB_ARCH="$(dpkg --print-architecture)"; \
        case "$DEB_ARCH" in \
            amd64|arm64) TERRAFORM_ARCH="$DEB_ARCH" ;; \
            *) echo "Unsupported Debian architecture for Terraform: $DEB_ARCH" >&2; exit 1 ;; \
        esac; \
    fi && \
    case "$TERRAFORM_ARCH" in \
        amd64|arm64) ;; \
        *) echo "Unsupported TARGETARCH for Terraform: $TERRAFORM_ARCH" >&2; exit 1 ;; \
    esac && \
    wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip" && \
    unzip "terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip" && \
    mv terraform /usr/bin/terraform && \
    rm -f "terraform_${TERRAFORM_VERSION}_linux_${TERRAFORM_ARCH}.zip" && \
    cd /tmp && \
    git clone https://github.com/neovim/neovim && \
    cd neovim && \
    git checkout stable && \
    make CMAKE_BUILD_TYPE=Release && \
    make install && \
    cd /tmp && \
    rm -rf neovim && \
    mkdir -p "$NVM_DIR" && \
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | PROFILE=/dev/null NVM_DIR="$NVM_DIR" bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install "$NODE_VERSION" && \
    nvm alias default "$NODE_VERSION" && \
    NODE_BIN_DIR="$NVM_DIR/versions/node/$(nvm version default)/bin" && \
    ln -sf "$NODE_BIN_DIR/node" /usr/local/bin/node && \
    ln -sf "$NODE_BIN_DIR/npm" /usr/local/bin/npm && \
    ln -sf "$NODE_BIN_DIR/npx" /usr/local/bin/npx && \
    ln -sf "$NODE_BIN_DIR/corepack" /usr/local/bin/corepack && \
    npm install -g tree-sitter-cli && \
    ln -sf "$NODE_BIN_DIR/tree-sitter" /usr/local/bin/tree-sitter && \
    printf '%s\n' \
        'export NVM_DIR=/usr/local/nvm' \
        '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"' \
        '[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"' \
        > /etc/profile.d/nvm.sh && \
    chmod 0644 /etc/profile.d/nvm.sh && \
    grep -q 'profile.d/nvm.sh' /etc/zsh/zshrc || echo '[ -s /etc/profile.d/nvm.sh ] && . /etc/profile.d/nvm.sh' >> /etc/zsh/zshrc && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["zsh"]
