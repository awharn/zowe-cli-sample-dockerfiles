#!/bin/bash

#########################################################
# Setup ENTRYPOINT script when running the image:       #
# - Installs the desired version of node js for root    #
# - Installs the desired version of node js for jenkins #
#########################################################

# Exit if any commands fail
set -e

# Extract Node.js version from env var
VERSION=$NODE_JS_NVM_VERSION
APIF=$ALLOW_PLUGIN_INSTALL_FAIL

if [ -z "$VERSION" ]; then
    echo "No version specified"
else
    # Execute the node installation script
    echo "Installing Node.js version $VERSION for current user..."
    install_node.sh $VERSION

    if [[ $EUID -ne 1000 ]]; then
        # Execute the script for user jenkins
        echo "Installing Node.js version $VERSION for jenkins user..."
        su -c "install_node.sh $VERSION" - jenkins
    fi

    # Do the install for zowe
    su -c "install_zowe.sh $APIF" - zowe
fi

# Execute passed cmd
exec "$@"
