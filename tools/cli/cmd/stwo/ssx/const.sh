#!/bin/bash

################################################################################
# SSX Constants
################################################################################
# Description:
#   Constants file for the ssx command group. This file should be sourced
#   by other scripts in the ssx command group and is excluded from direct
#   execution.
#
# Usage:
#   source ./const.sh
#
# Examples:
#   # Source in another script
#   source "${script_dir}/const.sh"
#   echo "SSX Version: ${SSX_VERSION}"
#
# Dependencies:
#   - bash 4.0+
#
# Author: BACHCLI Project
# Version: 1.0.0
################################################################################

# Prevent re-sourcing if already loaded
if [[ -n "${SSX_VERSION:-}" ]]; then
    return 0
fi

# This is a constants file for ssx that should be excluded from execution

SSX_VERSION="1.0.0"
SSX_TIMEOUT=60

# Export constants
export SSX_VERSION
export SSX_TIMEOUT
