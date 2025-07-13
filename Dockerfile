FROM archlinux/archlinux:base-devel

RUN curl -L https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz -O
RUN tar -xvf nvim-linux-x86_64.tar.gz
RUN mv nvim-linux-x86_64 /opt/nvim
RUN echo "append_path '/opt/nvim/bin'" >> /etc/profile.d/extra-global-paths.sh

# Create non root user
RUN mkdir /home/user
RUN useradd -G wheel -d /home/user user

# Copy config files and set owner to user
WORKDIR /home/user
COPY ./.config .config
RUN chown -R user /home/user

# Allow no password sudo
RUN echo "user ALL=NOPASSWD:ALL" | sudo EDITOR="tee -a" visudo

# Install packages
RUN yes | pacman -Sy git lua npm

# Use image as non-root
USER user

