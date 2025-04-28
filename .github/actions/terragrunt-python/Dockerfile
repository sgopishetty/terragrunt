# Dockerfile used in execution of Github Action
FROM gruntwork/terragrunt:0.2.0
LABEL maintainer="Gruntwork <info@gruntwork.io>"

ENV MISE_CONFIG_DIR=~/.config/mise
ENV MISE_STATE_DIR=~/.local/state/mise
ENV MISE_DATA_DIR=~/.local/share/mise
ENV MISE_CACHE_DIR=~/.cache/mise
ENV ASDF_HASHICORP_TERRAFORM_VERSION_FILE=.terraform-version

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    curl \
    git \
    jq \
    unzip \
    wget \
    sudo \
    python3 \
    python3-pip \
    openssh-client=1:8.9p1-3ubuntu0.11 \
    libkrb5support0 \
    libkrb5-3 \
    libk5crypto3 \
    libgssapi-krb5-2 \
    git-man \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install \
    && rm -rf aws awscliv2.zip

COPY ["./src/main.sh", "/action/main.sh"]

RUN chmod +x /action/main.sh

ENTRYPOINT ["/action/main.sh"]