FROM archlinux/archlinux:base-devel AS base

ARG PYTHON_VERSION=3.11

# Install Neovim
# We keep the folder name 'nvim-linux-x86_64' to match the PATH in my .zshrc
RUN curl -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -O && \
    tar -xvf nvim-linux-x86_64.tar.gz && \
    mv nvim-linux-x86_64 /opt/nvim-linux-x86_64

# Install Packages
RUN pacman -Syu --noconfirm git lua51 npm pyenv unzip ripgrep fd luarocks xclip xsel zsh fzf zoxide xdg-utils lsof \
	tree-sitter-cli

# Create non-root user with Zsh
RUN useradd -m -G wheel -d /home/user -s /bin/zsh user

# Copy config files
WORKDIR /home/user
COPY ./.config .config

RUN chown -R user:user /home/user

# Allow no-password sudo
RUN echo "user ALL=NOPASSWD:ALL" | EDITOR="tee -a" visudo

USER user

# Append Pyenv logic to .zshrc so it loads when you enter the container
RUN echo 'export PYENV_ROOT="$HOME/.pyenv"' >> .zshrc && \
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> .zshrc && \
    echo 'eval "$(pyenv init -)"' >> .zshrc && \
    echo 'if [ -d .venv ]; then source .venv/bin/activate; fi' >> .zshrc

WORKDIR /home/user/.config/nvim

# Manually initialize pyenv in this one-liner because .zshrc isn't loaded in non-interactive builds.
RUN zsh -c 'export PYENV_ROOT="$HOME/.pyenv" && \
    export PATH="$PYENV_ROOT/bin:$PATH" && \
    eval "$(pyenv init -)" && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION} && \
    python -m venv .venv && \
    source .venv/bin/activate && \
    pip install -r requirements.txt && \
    python -m ipykernel install --user --name=nvim-venv --display-name "Python (Nvim venv)" && \
    mkdir -p /home/user/.local/share/jupyter/runtime'

RUN echo 'source $HOME/.config/.zshrc' >> /home/user/.zshrc

# Run Lazy Sync using the full path
RUN rm -f lazy-lock.json && \
    zsh -c 'export PYENV_ROOT="$HOME/.pyenv" && \
            export PATH="$PYENV_ROOT/bin:$PATH" && \
            eval "$(pyenv init -)" && \
            source .venv/bin/activate && \
            /opt/nvim-linux-x86_64/bin/nvim --headless \
            "+Lazy! sync" \
            "+MasonToolsInstallSync" \
            "+TSUpdateSync" \
            "+UpdateRemotePlugins" \
            +qa'

#### STAGE: rust ###

FROM base AS rust

USER root
RUN yes | pacman -Sy rustup
WORKDIR /home/user
COPY ./rust /tmp/rust
RUN cp -r /tmp/rust/* .config/nvim
RUN rm -rf /tmp/rust
USER user
RUN rustup default stable
RUN rustup component add rust-analyzer
RUN echo 'export PATH="/home/user/.cargo/bin:$PATH"' >> .bash_profile

#### STAGE: VUE ####

FROM base AS vue

USER root
WORKDIR /home/user
COPY ./vue /tmp/vue
RUN cp -r /tmp/vue/* .config/nvim
RUN rm -rf /tmp/vue
USER user

### STAGE: with-java ###

FROM base AS with-java
USER root
ARG JAVA_VERSION=8

WORKDIR /home/user
ENV INSTALL_DIR="/home/user/tools"
ENV JAVA_INSTALL_DIR="$INSTALL_DIR/JAVA"
ENV JAVA_HOME="$JAVA_INSTALL_DIR/$JAVA_VERSION"

RUN yes | pacman -Sy jq
RUN bash <<'EOF'
if [ -z "$INSTALL_DIR" ]; then
    echo "Error: INSTALL_DIR is not set."
    exit 1
fi

JAVA_INSTALL_DIR="${INSTALL_DIR%/}/JAVA"

# Define variables
ARCH="${ARCH:-x64}"
JAVA_VERSION="${JAVA_VERSION:-8}"
OS="linux"

if [[ -n "$FORCE_REINSTALL"  && "$FORCE_REINSTALL" != "false" ]]; then
    echo "Forced reinstall ..."
    rm -r "${JAVA_INSTALL_DIR%/}/${JAVA_VERSION}"
fi

if [ -d "${JAVA_INSTALL_DIR%/}/${JAVA_VERSION}" ]; then
    echo "Existing same version installation found, skipping download"
else
    echo "Existing same version installation not found, downloading ..."
    # Fetch the latest Zulu JDK 8 URL for Linux x64
    DOWNLOAD_URL=$(curl -s "https://api.azul.com/metadata/v1/zulu/packages?java_version=$JAVA_VERSION&os=$OS&arch=$ARCH&java_package_type=jdk&release_status=ga" | \
	jq -r '.[] | select(.latest) | .download_url' | \
	grep tar.gz | tail -n 1
    )

    # Check if a valid URL was found
    if [[ -z "$DOWNLOAD_URL" ]]; then
	echo "Error: Unable to fetch the latest Zulu JDK 8 download URL."
	exit 1
    fi

    echo "Found Zulu JDK 8 download URL: $DOWNLOAD_URL"

    # Download the JDK tarball
    FILE_NAME=$(basename "$DOWNLOAD_URL")
    curl -O "$DOWNLOAD_URL"

    echo "Proceeding with download: $DOWNLOAD_URL"

    curl -L -O "$DOWNLOAD_URL"

    echo "Untar $FILENAME to $JAVA_INSTALL_DIR ..."
    mkdir -p $JAVA_INSTALL_DIR && tar -xzvf $FILE_NAME -C $JAVA_INSTALL_DIR  > /dev/null && mv "${JAVA_INSTALL_DIR%/}/$(basename $FILE_NAME .tar.gz)" "${JAVA_INSTALL_DIR%/}/${JAVA_VERSION}"
fi
EOF

RUN echo "JAVA_HOME=$JAVA_HOME" >> /etc/profile && echo "PATH=$JAVA_HOME/bin:\$PATH" >> /etc/profile
RUN chown -R user $INSTALL_DIR
USER user

### STAGE: default ###

FROM base AS default
