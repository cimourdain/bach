#!/bin/bash

################################################################################
# SONE Constants
################################################################################
# Description:
#   Constants file for the sone command group. This file should be sourced
#   by other scripts in the sone command group and is excluded from direct
#   execution.
#
# Usage:
#   source ./const.sh
#
# Examples:
#   # Source in another script
#   source "${script_dir}/const.sh"
#   echo "Version: ${SONE_VERSION}"
#
# Dependencies:
#   - bash 4.0+
#
# Author: BACHCLI Project
# Version: 1.0.0
################################################################################

# Prevent re-sourcing if already loaded
if [[ -n "${SONE_VERSION:-}" ]]; then
    return 0
fi

# This is a constants file that should be excluded from execution
# It contains shared constants for the sone command group

SONE_VERSION="1.0.0"
SONE_DEFAULT_TIMEOUT=30
SONE_MAX_RETRIES=3

# Export constants
export SONE_VERSION
export SONE_DEFAULT_TIMEOUT
export SONE_MAX_RETRIES
