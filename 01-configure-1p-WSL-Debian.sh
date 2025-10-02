#!/bin/bash

################################################################################
# Configure git on WSL Debian in an idempotent manner.
#
# See `#term-Idempotency` definition at:
# https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html
#
# This shell script attempts to comply with:
# https://google.github.io/styleguide/shellguide.html
#
# Should (hopefully, mostly) pass analysis with ShellCheck, too:
# https://www.shellcheck.net
################################################################################

# Set variables

github_username="phil-gg"
github_project="configure-wsl2"
github_branch="main"
filename="01-configure-1p-WSL-Debian.sh"
runtime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
normal=$(printf '\033[0m')
redbold=$(printf '\033[91;1m')
greenbold=$(printf '\033[92;1m')
cyanbold=$(printf '\033[96;1m')
bluebold=$(printf '\033[94;1m')

# Now running `${filename}`

echo -e "\n${cyanbold}Now running ‘${filename}’${normal}"

# Make folder(s) if they don't exist

echo -e "$ mkdir -p ~/git/${github_username}/${github_project}/pkgbuild"
mkdir -p "${HOME}/git/${github_username}/${github_project}/pkgbuild"

# Navigate to working directory

echo -e "$ cd ~/git/${github_username}/${github_project}/pkgbuild"
cd "${HOME}/git/${github_username}/${github_project}/pkgbuild" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 101; }

# Check for presence of wget

wgetcheck=$(wget -V 2> /dev/null | head -c 8)
if [ "${wgetcheck}" != "GNU Wget" ]; then
echo -e "\n${cyanbold}Installing wget${normal}"
echo -e "$ sudo apt update && sudo apt install wget\n"
sudo apt update && sudo apt install wget
fi

# Network test

echo -e "\n${bluebold}Testing network connectivity${normal}"
echo -e "  wget -q --spider https://raw.githubusercontent.com\
/${github_username}\
/${github_project}\
/${github_branch}\
/${filename}"

if ! wget -q --spider https://raw.githubusercontent.com\
/${github_username}\
/${github_project}\
/${github_branch}\
/${filename} 2> /dev/null
then
echo "${redbold}  Offline${normal}"
exit 102
else
echo "${greenbold}  Online${normal}"
fi

# check package architecture

pkgarch=$(dpkg --print-architecture)
echo -e "\n${cyanbold}Checking package architecture${normal}"
echo -e "  dpkg --print-architecture"
echo -e "  ${pkgarch}"
if [[ "${pkgarch}" == "amd64" || "${pkgarch}" == "arm64" ]];
then
echo -e "${greenbold}  1password is available for this arch${normal}"
else
echo -e "${redbold}  Unsupported architecture. Exiting...${normal}"
exit 103
fi



# Check for presence of lynx

lynxcheck=$(lynx -version  2> /dev/null | head -c 4)
if [ "${lynxcheck}" != "Lynx" ]; then
echo -e "\n${cyanbold}Installing lynx${normal}"
echo -e "$ sudo apt update && sudo apt install lynx\n"
sudo apt update && sudo apt install lynx
fi







################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

# Log this latest `Config` operation and display runtime

echo -e "FILE: ${filename} | EXEC-TIME: ${runtime}" >> config-runs.log
echo -e "\n${bluebold}${filename} run at${normal}"
echo -e "  ${runtime}\n"
