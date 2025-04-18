FROM debian:bookworm-slim AS builder

ENV LANG=C.UTF-8

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    dpkg-dev \
    gcc \
    libc6-dev \
    libffi-dev \
    libgmp-dev \
    libgmp10 \
    libncurses-dev \
    libncurses5 \
    libtinfo5 \
    pkg-config \    
    libnuma-dev \
    libtinfo-dev \
    zlib1g-dev \
    zsh \
    curl \
    apt-utils \
    openssh-client \
    gnupg2 \
    dirmngr \
    iproute2 \
    procps \
    lsof \
    htop \
    net-tools \
    psmisc \
    curl \
    wget \
    rsync \
    ca-certificates \
    unzip \
    zip \
    vim-tiny \
    less \
    apt-transport-https \
    locales \
    sudo \
    g++ \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash -m $USERNAME --uid $USER_UID --gid $USER_GID \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME

USER $USERNAME

ENV PATH="/home/$USERNAME/.local/bin:/home/$USERNAME/.cabal/bin:/home/$USERNAME/.ghcup/bin:$PATH"
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
#ENV BOOTSTRAP_HASKELL_INSTALL_HLS=1
ENV BOOTSTRAP_HASKELL_MINIMAL=1
# ENV BOOTSTRAP_HASKELL_VERBOSE=1
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
RUN ghcup install ghc 9.8.4 --set \
    && ghcup install hls latest --set \
    && ghcup install stack latest --set \
    && ghcup install cabal 3.10.3.0 --set
    
RUN . /home/vscode/.ghcup/env \
    && cabal update \
    && cabal install hoogle \
    && stack config set system-ghc --global true \
    && stack install --resolver lts-23 fourmolu hlint haskell-dap ghci-dap haskell-debug-adapter hasktags stylish-haskell fast-tags \
    && stack clean \
    && cabal clean \
    && hoogle generate \
    && rm -rf /home/vscode/.ghcup/tmp/* \
    && rm -rf /home/vscode/.ghcup/cache/* \
    && rm -rf /home/vscode/.ghcup/logs/* \
    && rm -rf /home/vscode/.ghcup/trash/*

####### FINAL IMAGE #######
FROM debian:bookworm-slim AS release

ENV LANG=C.UTF-8

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
    build-essential \
    dpkg-dev \
    make \
    gcc \
    g++ \
    git \
    libc6-dev \
    libffi-dev \
    libgmp-dev \
    libgmp10 \
    libncurses-dev \
    libncurses5 \
    libtinfo5 \
    pkg-config \    
    libnuma-dev \
    libtinfo-dev \
    zlib1g-dev \
    # zsh \
    curl \
    apt-utils \
    openssh-client \
    gnupg2 \
    # dirmngr \
    iproute2 \
    procps \
    lsof \
    # btop \
    net-tools \
    psmisc \
    curl \
    wget \
    # rsync \
    ca-certificates \
    # unzip \
    # zip \
    # vim-tiny \
    less \
    apt-transport-https \
    locales \
    sudo \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash -m $USERNAME --uid $USER_UID --gid $USER_GID \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME

USER $USERNAME
ENV PATH="/home/$USERNAME/.local/bin:/home/$USERNAME/.cabal/bin:/home/$USERNAME/.ghcup/bin:$PATH"

COPY --from=builder --chown=${USER_UID}:${USER_GID} /home/$USERNAME/.ghcup /home/$USERNAME/.ghcup
#COPY --from=builder --chown=${USER_UID}:${USER_GID} /home/$USERNAME/.cabal /home/$USERNAME/.cabal
COPY --from=builder --chown=${USER_UID}:${USER_GID} /home/$USERNAME/.stack /home/$USERNAME/.stack
COPY --from=builder --chown=${USER_UID}:${USER_GID} /home/$USERNAME/.hoogle /home/$USERNAME/.hoogle
#COPY --from=builder --chown=${USER_UID}:${USER_GID} /home/$USERNAME/.local /home/$USERNAME/.local

RUN echo "source /home/vscode/.ghcup/env" >> /home/${USERNAME}/.bashrc
