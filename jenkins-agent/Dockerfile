# This Dockerfile is used to build an image capable of running the npm keytar node module
# It must be given the capability of IPC_LOCK or be run in privilaged mode to properly operate
FROM ubuntu:focal

USER root

ARG IMAGE_VERSION_ARG
ARG DEFAULT_NODE_VERSION=${IMAGE_VERSION_ARG:-14}

# Upgrade and install packages
RUN apt-get -q update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -q upgrade -y -o Dpkg::Options::="--force-confnew" --no-install-recommends
RUN DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends locales sudo wget unzip zip git curl libxss1 sshpass vim nano expect build-essential software-properties-common gnome-keyring libsecret-1-dev dbus-x11
RUN locale-gen en_US.UTF-8
RUN DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends openssh-server
RUN apt-get -q autoremove
RUN sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Get rid of dash and use bash instead
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# Install JDK 8 and 11
RUN add-apt-repository -y ppa:openjdk-r/ppa
RUN apt-get -q update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends openjdk-11-jre-headless openjdk-8-jre-headless openjdk-11-jdk openjdk-8-jdk maven ca-certificates-java
RUN update-ca-certificates -f
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Add Jenkins user
RUN sudo useradd jenkins --shell /bin/bash --create-home
RUN sudo usermod -a -G sudo jenkins
RUN echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers
RUN echo 'jenkins:jenkins' | chpasswd

COPY openssl.cnf /etc/ssl/openssl.cnf

# Add node version 14 which should bring in npm, add maven and build essentials and required ssl certificates to contact maven central
# expect is also installed so that you can use that to login to your npm registry if you need to
# Note: we'll install Node.js globally and include the build tools for pyhton - but nvm will override when the container starts
RUN curl -sL "https://deb.nodesource.com/setup_$DEFAULT_NODE_VERSION.x" | sudo -E bash -
RUN apt-get -q update
RUN DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends nodejs

RUN apt-get -q autoremove 
RUN apt-get -q clean -y 
RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/*.bin

# Install nvm to enable multiple versions of node runtime and define environment 
# variable for setting the desired node js version (defaulted to "current" for Node.js)
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# dd the jenkins users
RUN groupadd npmusers
RUN usermod -aG npmusers jenkins 

# Also install nvm for user jenkins
USER jenkins
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
USER root

ARG tempDir=/tmp/jenkins-npm-keytar
ARG sshEnv=/etc/profile.d/npm_setup.sh
ARG bashEnv=/etc/bash.bashrc

# First move the template file over
RUN mkdir ${tempDir}
COPY env.bashrc ${tempDir}/env.bashrc

# Next, make the file available to all to read and source
# RUN chmod +r /usr/local/env.sh
ENV ENV=${bashEnv}

# Create a shell file that applies the configuration for sessions. (anything not bash really)
RUN touch ${sshEnv}
RUN echo '#!bin/sh'>>${sshEnv} \
RUN cat ${tempDir}/env.bashrc>>${sshEnv}

# Create a properties file that is used for all bash sessions on the machine
# Add the environment setup before the exit line in the global bashrc file
RUN sed -i -e "/# If not running interactively, don't do anything/r ${tempDir}/env.bashrc" -e //N ${bashEnv}

# Cleanup after ourselves
RUN rm -rdf ${tempDir}

# Copy the setup script and node/nvm scripts for execution (allow anyone to run them)
ARG scriptsDir=/usr/local/bin/
COPY docker-entrypoint.sh ${scriptsDir}
COPY install_node.sh ${scriptsDir}
COPY install_zowe.sh ${scriptsDir}

RUN install_node.sh ${DEFAULT_NODE_VERSION}
RUN su -c "install_node.sh ${DEFAULT_NODE_VERSION}" - jenkins

ARG sshEnv=/etc/profile.d/dbus_start.sh
ARG loginFile=pam.d.config

# Copy the PAM configuration options to allow auto unlocking of the gnome keyring
COPY ${loginFile} ${tempDir}/${loginFile}

# Enable unlocking for ssh
RUN cat ${tempDir}/${loginFile}>>/etc/pam.d/sshd

# Enable unlocking for regular login
RUN cat ${tempDir}/${loginFile}>>/etc/pam.d/login

# Copy the profile script 
COPY dbus_start ${tempDir}/dbus_start

# Enable dbus for ssh and most other native shells (interactive)
RUN touch ${sshEnv}
RUN echo '#!/bin/sh'>>${sshEnv}
RUN cat ${tempDir}/dbus_start>>${sshEnv}

# Start in home directory
RUN echo "cd ~" >> ${bashEnv} && echo "cd ~" >> /home/jenkins/.bashrc

# Enable for all bash profiles
# Add the dbus launch before exiting when not running interactively
RUN sed -i -e "/# If not running interactively, don't do anything/r ${tempDir}/dbus_start" -e //N ${bashEnv}

# Install zowe
RUN su -c "install_zowe.sh" - jenkins

RUN printf "\nif test -z \"\$SSH_CONNECTION\"; then\n\techo jenkins | gnome-keyring-daemon --unlock --components=secrets > /dev/null\nfi\n" >> /home/jenkins/.bashrc

# Cleanup any temp files we have created
RUN rm -rdf ${tempDir}

# Execute the setup script when the image is run. Setup will install the desired version via 
# nvm for both the root user and jenkins - then start the ssh service
ENTRYPOINT ["docker-entrypoint.sh"]

# Standard SSH port
EXPOSE 22

# Exec ssh
CMD ["/usr/sbin/sshd", "-D"]