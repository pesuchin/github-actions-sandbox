# syntax = docker/dockerfile:experimental
FROM python:3.9.0-slim-buster

ARG RUNTIME_DEPENDENCIES="openssh-client"
ARG BUILD_DEPENDENCIES="git curl"

WORKDIR /app

# Copy only files needed to build
COPY pyproject.toml poetry.lock ./

RUN \
    #--mount=type=cache,target=/root/.cache/pip \
    #--mount=type=secret,id=ssh,destination=/root/.ssh/id_rsa \
    #set -ex; \
    # Install runtime and build packages
    apt-get update && \
    apt-get install -y --no-install-recommends ${RUNTIME_DEPENDENCIES} ${BUILD_DEPENDENCIES}\
    && \
    # For fix this issue https://github.com/PyMySQL/PyMySQL/issues/817
    # https://www.debian.org/releases/stable/amd64/release-notes/ch-information.en.html#openssl-defaults
    sed -i 's,^\(MinProtocol[ ]*=\).*,\1'TLSv1.0',g' /etc/ssl/openssl.cnf && \
    # Install python libraries from pypi (ref: https://github.com/BretFisher/php-docker-good-defaults/issues/6)
    mkdir /root/.ssh && chmod 0700 /root/.ssh && \
    ssh-keyscan -H github.com >> /root/.ssh/known_hosts && \
    pip install --no-cache-dir "poetry==1.1.4" && \
    poetry config virtualenvs.create false && \
    poetry install --no-dev --no-interaction --no-ansi &&\
    # Remove redundant files
    pip uninstall --yes poetry && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get purge -y --auto-remove ${BUILD_DEPENDENCIES}

# Copy entire app
COPY . /app

WORKDIR /app/app/

EXPOSE 8000
CMD ["uvicorn", "main:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]
