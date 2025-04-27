FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu22.04
ENV RUNNING_IN_DOCKER=true
ARG bells=true \
    whistles=true
ENV BELLS=${bells} \
    WHISTLES=${whistles}

ENV PYTHONUNBUFFERED=1 \
    DEBIAN_FRONTEND=noninteractive


USER root

# RUN if ! id -u ubuntu >/dev/null 2>&1; then \
#       useradd -m ubuntu; \
#       usermod -aG sudo ubuntu \
#     ;fi

RUN apt-get update -y \
    && apt-get upgrade -y \
    && apt install -y \
    sudo \
    fortune-mod \
    # fortunes-bofh-excuses \
    cowsay

WORKDIR /root
# RUN adduser -D nonroot

# ---------------------------------------------------------------------------- #
#                                 Optional Packages                            #
# ---------------------------------------------------------------------------- #
RUN if ${BELLS} ; then \
        apt install -y \
        curl \
        git \
        nano \
        plocate \
        wget \
        # neofetch \
    ;fi

# ---------------------------------------------------------------------------- #
#                            Optional - Shell Magic                            #
# ---------------------------------------------------------------------------- #
RUN if ${WHISTLES} && ${BELLS}; then \
        apt install -y \
        zsh \
        locales \
        # lsd \
    ;fi

RUN if [ "${WHISTLES}" = "true" ] && [ "${BELLS}" = "true" ]; then \
        echo "Downloading and installing lsd v1.1.5 from GitHub..."; \
        curl -LO https://github.com/lsd-rs/lsd/releases/download/v1.1.5/lsd_1.1.5_amd64.deb && \
        dpkg -i lsd_1.1.5_amd64.deb && \
        rm lsd_1.1.5_amd64.deb \
    ;fi




# --------------------------------- ROOT USER -------------------------------- #
RUN if ${WHISTLES} && ${BELLS} ; then \
        chsh -s /bin/zsh root \
        && locale-gen en_US.UTF-8 \
        && update-locale LANG=en_US.UTF-8 \
        && git clone --depth=1 https://github.com/mattmc3/antidote.git $HOME/.antidote \
    ;fi

# Cache busting to avoid using outdated curl results
ADD "https://api.github.com/repos/Aristeidis-Androutsopoulos/vm_like_docker/commits/main" latest_commit
RUN if ${WHISTLES} && ${BELLS}; then \
        rm latest_commit \
        && curl -LO https://raw.githubusercontent.com/Aristeidis-Androutsopoulos/vm_like_docker/main/.zsh_plugins.txt \
        && curl -LO https://raw.githubusercontent.com/Aristeidis-Androutsopoulos/vm_like_docker/main/.zshrc \
    ;fi
# ADD .zshrc $HOME


RUN if ${WHISTLES} && ${BELLS}; then \
        /bin/zsh $HOME/.zshrc \
        # && cp $HOME/.zshrc /home/ubuntu \
        # && cp $HOME/.zsh_plugins.txt /home/ubuntu \
        # && cp -r $HOME/.antidote /home/ubuntu \
    ;fi




# ------------------------------- NON-ROOT USER ------------------------------ #
# RUN if ${WHISTLES} && ${BELLS}; then \
#         passwd -d ubuntu && chsh -s /bin/zsh ubuntu \
#     ;fi
# USER ubuntu

# ADD .zshrc $HOME

# RUN if ${WHISTLES} && ${BELLS}; then \
#         /bin/zsh $HOME/.zshrc \
#     ;fi

# WORKDIR /home/ubuntu/.cache/antidote/https-COLON--SLASH--SLASH-github.com-SLASH-sindresorhus-SLASH-pure/
# RUN if ${WHISTLES} && ${BELLS}; then \
#         sed -i '0,/prompt_pure_is_inside_container/s//true/' pure.zsh \
#         && /bin/zsh $HOME/.zshrc \
#     ;fi





# ---------------------------------------------------------------------------- #
#                                   clean-ups                                  #
# ---------------------------------------------------------------------------- #
# USER root
RUN apt-get clean \
&& apt clean \
### This removes the apt lists so apt install no longer works
# && rm -rf /var/lib/apt/lists/* \
&& rm -rf /tmp/* /var/tmp/*
# RUN rm -rf /usr/share/doc /usr/share/man /usr/share/info /usr/share/locale/ /var/log/*

# USER ubuntu
WORKDIR /env

ENTRYPOINT [ "/bin/sh", "-c", "$(awk -F: -v user=$(whoami) '$1 == user {print $7}' /etc/passwd)" ]
# ENTRYPOINT [ "/bin/sh", "-c", "if [ \"$WHISTLES\" = \"true\" ] && [ \"$BELLS\" = \"true\" ]; then exec /bin/zsh; else exec /bin/bash; fi" ]
