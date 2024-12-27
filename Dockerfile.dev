# Dockerfile.dev
FROM archlinux:latest

# Install development dependencies
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        base-devel \
        git \
        python \
        python-pip \
        systemd \
        qemu-img \
        arch-install-scripts \
        sudo \
        vim \
        curl \
        wget

# Install mkosi
RUN pip install mkosi

# Create development user
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME

# Set up development environment
WORKDIR /workspace
RUN chown ${USERNAME}:${USERNAME} /workspace

USER $USERNAME

# Add helper scripts
COPY --chown=$USERNAME:$USERNAME scripts/entrypoint.sh /usr/local/bin/
RUN sudo chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]