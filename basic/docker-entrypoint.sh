#!/bin/bash

#########################################################
# Setup ENTRYPOINT script when running the image:       #
# - Installs Zowe CLI and plugins for root              #
# - Installs Zowe CLI and plugins for zowe           #
#########################################################

# Exit if any commands fail
set -e

# Execute passed cmd
exec "$@"
