FROM ubuntu:focal

USER root
ENV DEFAULT_NODE_VERSION=16
ENV ZOWE_VERSION=zowe-v2-lts
ENV DEBIAN_FRONTEND="noninteractive"

# Add Zowe user and update password
RUN useradd zowe --shell /bin/bash --create-home && echo 'zowe:zowe' | chpasswd
RUN echo "cd ~" >> /home/zowe/.bashrc

# Install Node, plugin prereqs
RUN apt-get update && apt-get install -y curl build-essential && curl -fsSL https://deb.nodesource.com/setup_${DEFAULT_NODE_VERSION}.x | bash - && apt-get install -y nodejs && apt-get -q autoremove && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* /var/cache/apt/*.bin

# Install Zowe CLI
RUN npm install -g @zowe/cli@${ZOWE_VERSION} --ignore-scripts
USER zowe
RUN zowe plugins install @zowe/cics-for-zowe-cli@${ZOWE_VERSION} @zowe/db2-for-zowe-cli@${ZOWE_VERSION} @zowe/ims-for-zowe-cli@${ZOWE_VERSION} @zowe/mq-for-zowe-cli@${ZOWE_VERSION} @zowe/zos-ftp-for-zowe-cli@${ZOWE_VERSION}
RUN mkdir -p ~/.zowe/settings && echo '{"overrides":{"CredentialManager":false}}' > ~/.zowe/settings/imperative.json

# Uncomment to enable daemon mode by default
# RUN echo 'export PATH=/home/zowe/.zowe/bin:$PATH' >> ~/.bashrc && zowe daemon enable

CMD ["/bin/bash"]