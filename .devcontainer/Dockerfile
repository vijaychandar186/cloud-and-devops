FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Required by Ansible's apt module in check mode
RUN apt-get update && apt-get install -y python3-apt && rm -rf /var/lib/apt/lists/*
