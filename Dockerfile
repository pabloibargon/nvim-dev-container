FROM archlinux/archlinux:base-devel AS base

ARG PYTHON_VERSION=3.11

RUN curl -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -O
RUN tar -xvf nvim-linux-x86_64.tar.gz
RUN mv nvim-linux-x86_64 /opt/nvim
RUN echo "append_path '/opt/nvim/bin'" >> /etc/profile.d/extra-global-paths.sh

# Create non root user
RUN mkdir /home/user
RUN useradd -G wheel -d /home/user user

# Copy config files and set owner to user
WORKDIR /home/user

# Install packages & setup python
# lua needs to be 5.1
RUN yes | pacman -Sy git lua51 npm pyenv unzip ripgrep fd luarocks
RUN echo 'eval "$(pyenv init --path)" && eval "$(pyenv init -)"' >> .bash_profile
RUN echo 'if [ -d .venv ] ; then source .venv/bin/activate && python -m ipykernel install --user --name=initial-venv --display-name "Python (Initial venv)" ; fi' >> .bash_profile

COPY ./.config .config
RUN chown -R user /home/user

# Allow no password sudo
RUN echo "user ALL=NOPASSWD:ALL" | sudo EDITOR="tee -a" visudo

# Use image as non-root
USER user

WORKDIR /home/user/.config/nvim
RUN bash -c 'source /home/user/.bash_profile && pyenv install ${PYTHON_VERSION} && pyenv global ${PYTHON_VERSION} && python -m venv .venv &&\
	source .venv/bin/activate && pip install -r requirements.txt  && python -m ipykernel install --user --name=nvim-venv --display-name "Python (Nvim venv)" && mkdir -p /home/user/.local/share/jupyter/runtime'
RUN bash -c '/opt/nvim/bin/nvim --headless "+Lazy! sync" +UpdateRemotePlugins +qa'

#### STAGE: rust ###

FROM base AS rust

USER root
RUN yes | pacman -Sy rust rust-analyzer
WORKDIR /home/user
COPY ./rust /tmp/rust
RUN cp -r /tmp/rust/* .config/nvim
RUN rm -rf /tmp/rust

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
