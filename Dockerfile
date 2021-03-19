# Save & assign to variables arguments passed from the docker build command.
ARG LINUX_ALPINE_VERSION

# Build this image from the lightweight Linux Alpine.
FROM alpine:$LINUX_ALPINE_VERSION

# Make the src default folder for all operations.
RUN mkdir -p /src
WORKDIR /src

COPY scripts /src/scripts
ENV PATH="/src/scripts:${PATH}"

# Install the basic tools.
RUN apk add --update \
    bash \
    jq \
    python3 \
    python3-dev \
    py3-pip \
    mysql-client

# Install AWS CLI.
ARG AWS_CLI_VERSION
RUN pip install awscli==$AWS_CLI_VERSION --upgrade --user && \
    rm /var/cache/apk/*
ENV PATH="~/.local/bin:${PATH}"
