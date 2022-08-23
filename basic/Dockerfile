FROM ubuntu:focal

USER root

ARG sshEnv=/etc/profile.d/npm_setup.sh
ARG bashEnv=/etc/bash.bashrc
ARG scriptsDir=/usr/local/bin/

ENV ENV=${bashEnv}
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV DEFAULT_NODE_VERSION=16

# Upgrade package on image
RUN apt-get update -qqy &&\
    apt-get -qqy install locales &&\
    locale-gen en_US.UTF-8 &&\
    apt-get -qqy update &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends &&\
    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends git curl libxss1 vim nano software-properties-common cmake &&\
    apt-get -q autoremove &&\
    mkdir -p /var/run/sshd

# Add Zowe user
RUN useradd zowe --shell /bin/bash --create-home &&\
    echo 'zowe:zowe' | chpasswd

# Fix OpenSSL problems with TLS 1.2
COPY openssl.cnf /etc/ssl/openssl.cnf

# Install Node, plugin prereqs
RUN curl -sL https://deb.nodesource.com/setup_${DEFAULT_NODE_VERSION}.x | bash -
RUN apt-get install -y nodejs expect build-essential

# Get rid of dash and use bash instead
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# Copy the setup script and node scripts for execution (allow anyone to run them)
COPY docker-entrypoint.sh ${scriptsDir}

# Start in home directory
RUN echo "cd ~" >> ${bashEnv} && echo "cd ~" >> /home/zowe/.bashrc

COPY install_zowe.sh ${scriptsDir}

# Install zowe
RUN install_zowe.sh

# Cleanup
RUN apt-get -q autoremove && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Standard SSH port
EXPOSE 22

# Execute the setup script when the image is run.
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command
CMD ["/usr/sbin/sshd", "-D"]
