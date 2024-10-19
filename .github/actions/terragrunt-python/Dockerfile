# Dockerfile used in execution of Github Action
FROM gruntwork/terragrunt:0.2.0
LABEL maintainer="Gruntwork <info@gruntwork.io>"

ENV MISE_CONFIG_DIR=~/.config/mise
ENV MISE_STATE_DIR=~/.local/state/mise
ENV MISE_DATA_DIR=~/.local/share/mise
ENV MISE_CACHE_DIR=~/.cache/mise
ENV ASDF_HASHICORP_TERRAFORM_VERSION_FILE=.terraform-version

RUN apt-get update \
    && apt-get install -y \
    curl \
    git \
    jq \
    unzip \
    wget \
    sudo \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

COPY ["./src/main.sh", "/action/main.sh"]

RUN chmod +x /action/main.sh

ENTRYPOINT ["/action/main.sh"]