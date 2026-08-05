# image to set in arc runner scale set for github actions
FROM ghcr.io/actions/actions-runner:latest

ARG KUBECTL_VERSION=v1.30.0
ARG HELM_VERSION=v3.15.0
ARG KUBELOGIN_VERSION=v0.2.19

USER root

# Travailler dans /tmp pour préserver les fichiers et droits du runner
WORKDIR /tmp

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        gnupg \
        lsb-release \
        apt-transport-https \
        unzip \
        jq \
    && rm -rf /var/lib/apt/lists/*

# Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# kubectl
RUN curl -sLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm kubectl

# helm
RUN curl -sL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" | tar xz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && rm -rf linux-amd64

# kubelogin
RUN curl -sLO "https://github.com/Azure/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip" \
    && unzip -q kubelogin-linux-amd64.zip \
    && mv bin/linux_amd64/kubelogin /usr/local/bin/kubelogin \
    && rm -rf kubelogin-linux-amd64.zip bin

# Rétablir les droits sur le répertoire du runner et restaurer le WORKDIR
RUN chown -R runner:runner /actions-runner 2>/dev/null || chown -R runner:runner /home/runner 2>/dev/null || true

WORKDIR /actions-runner

USER runner