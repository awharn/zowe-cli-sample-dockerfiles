FROM ubuntu:focal

USER root

ARG tempDir=/tmp/zowe
ARG sshEnv=/etc/profile.d/npm_setup.sh
ARG bashEnv=/etc/bash.bashrc
ARG scriptsDir=/usr/local/bin/

ENV ENV=${bashEnv}
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV DEFAULT_NODE_VERSION=16.17.0

# Upgrade package on image
RUN apt-get update -qqy &&\
    apt-get -qqy install locales &&\
    locale-gen en_US.UTF-8 &&\
    apt-get -qqy update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends git curl libxss1 vim nano openssh-server software-properties-common cmake &&\
    apt-get -q autoremove &&\
    mkdir -p /var/run/sshd

# Add Zowe user
RUN useradd zowe --shell /bin/bash --create-home &&\
    echo 'zowe:zowe' | chpasswd

# Fix OpenSSL problems with TLS 1.2
COPY openssl.cnf /etc/ssl/openssl.cnf

# Install Node, nvm, plugin prereqs
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs expect build-essential

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
RUN groupadd npmusers && usermod -aG npmusers zowe && usermod -aG npmusers root

# Also install nvm for user zowe
USER zowe
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

USER root

# Get rid of dash and use bash instead
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# First move the template file over
RUN mkdir ${tempDir}
COPY env.bashrc ${tempDir}/env.bashrc

# Create a properties file that is used for all bash sessions on the machine
# Add the environment setup before the exit line in the global bashrc file
RUN sed -i -e "/# If not running interactively, don't do anything/r ${tempDir}/env.bashrc" -e //N ${bashEnv}

# Copy the setup script and node/nvm scripts for execution (allow anyone to run them)
COPY docker-entrypoint.sh ${scriptsDir}
COPY install_node.sh ${scriptsDir}

# Install Node
RUN install_node.sh $DEFAULT_NODE_VERSION
RUN su -c "install_node.sh $DEFAULT_NODE_VERSION" - zowe

# Create a shell file that applies the configuration for sessions.
RUN touch ${sshEnv} \
    && echo '#!bin/sh'>>${sshEnv} \
    && cat ${tempDir}/env.bashrc>>${sshEnv}

# Start in home directory
RUN echo "cd ~" >> ${bashEnv} && echo "cd ~" >> /home/zowe/.bashrc

COPY install_zowe.sh ${scriptsDir}

# Install zowe
RUN install_zowe.sh
RUN su -c "install_zowe.sh" - zowe

# Cleanup
RUN apt-get -q autoremove && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin
RUN rm -rdf ${tempDir}

# Standard SSH port
EXPOSE 22

# Execute the setup script when the image is run. Setup will install the desired version via 
# nvm for both the root user and zowe - then start the ssh service
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command
CMD ["/usr/sbin/sshd", "-D"]
