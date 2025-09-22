#!/bin/bash

################################################################################
# Configure Firefox on WSL Debian in an idempotent manner.
#
# See `#term-Idempotency` definition at:
# https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html
#
# This shell script attempts to comply with:
# https://google.github.io/styleguide/shellguide.html
################################################################################

# Set variables

github_username="phil-gg"
github_project="configure-wsl2"
github_branch="main"
filename="02-configure-firefox-WSL-Debian.sh"
runtime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
normal=$(printf '\033[0m')
redbold=$(printf '\033[91;1m')
greenbold=$(printf '\033[92;1m')
cyanbold=$(printf '\033[96;1m')
bluebold=$(printf '\033[94;1m')

# Now running `${filename}`

echo -e "\n${cyanbold}Now running ‘${filename}’${normal}"

# Make folder(s) if they don't exist

mkdir -p "${HOME}/git/${github_username}/${github_project}"

# Navigate to working directory

cd "${HOME}/git/${github_username}/${github_project}" \
|| { echo "Failure"; exit 1; }

# Set run time for this latest `Config` operation

echo -e "$\n{filename} run at ${runtime}" >> config-runs.log
echo -e "\n${bluebold}Config run at${normal}"
echo -e "  ${runtime}"

# Set alias commands
  # TODO
  # alias = update-alpine
  # cd /git/${github_username}/${github_project} && busybox sh script-updater.sh

################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

# Test creating file in working directory

echo -n "\
${runtime}
One
Two
Three
" > test.log

# Test echo some commands to stdout

echo -e "\n${bluebold}\
Commands to locate & view files this script created\
${normal}"

echo -e "\
  cd /git/${github_username}/${github_project} && ls
  cat test.log
  cat lastrun-upd.log
  cat lastrun-conf.log
 "
