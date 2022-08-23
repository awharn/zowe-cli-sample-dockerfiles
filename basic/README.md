# Zowe CLI Docker Container

This repository contains the files required to create a Zowe CLI docker container with root access

To build the container, run `docker build .`
To run the container as a standard user, run `docker run -it -u zowe <tag> /bin/bash`
To run the container as root, run `docker run -it -u root <tag> /bin/bash`
The container is running SSH. The default password for the jenkins user is `jenkins`.

Requirements:

- Access to the internet

Environment variables:

- ALLOW_PLUGIN_INSTALL_FAIL - Allows plugin installation to fail in the entrypoint without stopping the container if set