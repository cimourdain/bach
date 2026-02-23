#!/bin/bash

################################################################################
# SONE Static Data
################################################################################
# Description:
#   Static data definitions for the sone command group. This file should be
#   sourced by other scripts in the sone command group and is excluded from
#   direct execution.
#
# Usage:
#   source ./statics.sh
#
# Examples:
#   # Source in another script
#   source "${script_dir}/statics.sh"
#   echo "Key1 value: ${SONE_STATIC_DATA[key1]}"
#
# Dependencies:
#   - bash 4.0+
#
# Author: BACHCLI Project
# Version: 1.0.0
################################################################################

# Prevent re-sourcing if already loaded
if declare -p SONE_STATIC_DATA &>/dev/null; then
    return 0
fi

# This is a statics file that should be excluded from execution
# It contains static data for the sone command group

declare -A SONE_STATIC_DATA=(
    ["key1"]="value1"
    ["key2"]="value2"
    ["key3"]="value3"
)

# Export static data
export SONE_STATIC_DATA
