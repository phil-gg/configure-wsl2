#!/bin/bash

################################################################################
# Configure 1password on WSL Debian in an idempotent manner.
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

# Check for presence of wget

wgetcheck=$(wget -V 2> /dev/null | head -c 8)
if [ "${wgetcheck}" != "GNU Wget" ]; then
echo -e "\n${cyanbold}Installing wget${normal}"
echo -e "$ sudo apt update && sudo apt install wget\n"
sudo apt update && sudo apt install wget
fi

# Network test

echo -e "\n${bluebold}Testing network connectivity${normal}"
echo -e "$ wget -q --spider https://raw.githubusercontent.com\
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
echo "${redbold}> Offline${normal}"
exit 101
else
echo "${greenbold}> Online${normal}"
fi

# check package architecture

pkgarch=$(dpkg --print-architecture)
echo -e "\n${cyanbold}Checking package architecture${normal}"
echo -e "$ dpkg --print-architecture"
echo -e "> ${pkgarch}"
if [[ "${pkgarch}" == "amd64" || "${pkgarch}" == "arm64" ]]
then
echo -e "${greenbold}> 1password is available for this arch${normal}"
else
echo -e "${redbold}> Unsupported architecture, exiting${normal}\n"
exit 102
fi

# Explicitly install 1password dependencies

echo -e "\n${cyanbold}Explicitly install 1password dependencies${normal}"
echo -e "${cyanbold}( this dependency list was extracted from deb file in \
Oct-2025 )${normal}"
echo -e "${cyanbold}( https://downloads.1password.com/linux/debian/amd64/stable\
/1password-latest.deb )${normal}"
echo -e '
sudo apt install \
curl \
gnupg2 \
libasound2 \
libatk-bridge2.0-0 \
libatk1.0-0 \
libc6 \
libcurl4 \
libdrm2 \
libgbm1 \
libgtk-3-0 \
libnotify4 \
libnss3 \
libxcb-shape0 \
libxcb-xfixes0 \
libxshmfence1 \
libudev1 \
xdg-utils \
libappindicator3-1 
'
sudo apt install \
curl \
gnupg2 \
libasound2 \
libatk-bridge2.0-0 \
libatk1.0-0 \
libc6 \
libcurl4 \
libdrm2 \
libgbm1 \
libgtk-3-0 \
libnotify4 \
libnss3 \
libxcb-shape0 \
libxcb-xfixes0 \
libxshmfence1 \
libudev1 \
xdg-utils \
libappindicator3-1


# ################## #
# ON AMD64 ARCH ONLY #
# ################## #

# Manage keys and repos

# ################## #
# ON ARM64 ARCH ONLY #
# ################## #

# Make folder(s) if they don't exist

echo -e "\n${cyanbold}Build our own deb package for arm64 arch${normal}"
echo -e "$ mkdir -p ~/git/${github_username}/${github_project}/pkgbuild"
mkdir -p "${HOME}/git/${github_username}/${github_project}/pkgbuild"

# Navigate to working directory

echo -e "$ cd ~/git/${github_username}/${github_project}/pkgbuild"
cd "${HOME}/git/${github_username}/${github_project}/pkgbuild" 2> /dev/null \
|| { echo -e "${redbold}> Failed to change directory, exiting${normal}\n"\
; exit 103; }

# Check for presence of lynx

lynxcheck=$(lynx -version  2> /dev/null | head -c 4)
if [ "${lynxcheck}" != "Lynx" ]; then
echo -e "\n${cyanbold}Installing lynx${normal}"
echo -e "$ sudo apt update && sudo apt install lynx\n"
sudo apt update && sudo apt install lynx
fi

# Get latest 1password versions

longversion1p=$(lynx -dump https://releases.1password.com/linux/stable \
| grep -oE "Updated\sto.*$")
shortversion1p=$(echo -e "${longversion1p}" | grep -oE "[0-9]+\.[0-9\.]+")

echo -e "\n${cyanbold}Latest status message for 1password linux stable${normal}"
echo -e "> ${longversion1p}"

# get latest 1password amd64 deb package

echo -e "\n${cyanbold}Get latest 1password amd64 deb package${normal}"
echo -e "$ wget -O 1password_${shortversion1p}_amd64.deb \
https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb"
# echo -e "\n"
# wget -O "1password_${shortversion1p}_amd64.deb" \
# https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb



################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

# Log this latest `Config` operation and display runtime

echo -e "FILE: ${filename} | EXEC-TIME: ${runtime}" \
>> "${HOME}/git/${github_username}/${github_project}/config-runs.log"
echo -e "\n${bluebold}${filename} run at${normal}"
echo -e "> ${runtime}\n"
