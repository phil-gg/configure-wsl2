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
filename="01-configure-repos-update-dpkg-WSL-Debian.sh"
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
if [[ "${wgetcheck}" != "GNU Wget" ]]; then
echo -e "\n${cyanbold}Installing wget${normal}"
echo -e "$ sudo apt update && sudo apt -y install wget\n"
sudo apt update && sudo apt -y install wget
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

# Check for presence of gpg

wgetcheck=$(gpg --version 2> /dev/null | head -c 11)
if [[ "${wgetcheck}" != "gpg (GnuPG)" ]]; then
echo -e "\n${cyanbold}Installing gpg${normal}"
echo -e "$ sudo apt update && sudo apt -y install gpg\n"
sudo apt update && sudo apt -y install gpg
fi

# check for presence of debsig-verify

debsigcheck=$(debsig-verify --version 2> /dev/null | head -c 6)
if [[ "${debsigcheck}" != "Debsig" ]]; then
echo -e "\n${cyanbold}Installing debsigs${normal}"
echo -e "$ sudo apt update && sudo apt -y install debsigs\n"
sudo apt update && sudo apt -y install debsigs
fi

# general system update

echo -e "\n${cyanbold}Check for and apply package updates${normal}"
echo -e "$ sudo apt update && sudo apt upgrade\n"
sudo apt update && sudo apt upgrade

# keep apt tidy

echo -e "\n${cyanbold}Make apt autoremove work properly${normal}"
echo -e "$ sudo apt-mark minimize-manual -y\n"
sudo apt-mark minimize-manual -y
echo -e "\n${cyanbold}Clean up apt packages${normal}"
echo -e "$ sudo apt autoremove --purge\n"
sudo apt autoremove --purge

# run tidy again if this variable is changed to 1

pkgchanges=0

# check package architecture

pkgarch=$(dpkg --print-architecture)
echo -e "\n${cyanbold}Checking package architecture${normal}"
echo -e "$ dpkg --print-architecture"
echo -e "> ${pkgarch}"
if [[ "${pkgarch}" == "amd64" || "${pkgarch}" == "arm64" ]]; then
echo -e "${greenbold}> 1password is available for this arch${normal}"
else
echo -e "${redbold}> Unsupported architecture, exiting${normal}\n"
exit 102
fi

# Install mozilla deb repo (on any arch)

expectedMozillaKey="35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3"

actualMozillaKey=$(gpg -n -q --import --import-options import-show \
/usr/share/keyrings/mozilla-archive-keyring.asc 2> /dev/null \
| grep -oE '[0-9A-F]{40}')

if [[ "${actualMozillaKey}" != "${expectedMozillaKey}" ]]; then

echo -e "\n${cyanbold}Add Mozilla deb repo${normal}"
echo -e "$ wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg | \
sudo tee /usr/share/keyrings/mozilla-archive-keyring.asc 1> /dev/null"
wget -qO- https://packages.mozilla.org/apt/repo-signing-key.gpg | \
sudo tee /usr/share/keyrings/mozilla-archive-keyring.asc 1> /dev/null

actualMozillaKey=$(gpg -n -q --import --import-options import-show \
/usr/share/keyrings/mozilla-archive-keyring.asc 2> /dev/null \
| grep -oE '[0-9A-F]{40}')

echo -e "\n${bluebold}  Check signing key${normal}"
echo -e "  > ${expectedMozillaKey} = expected-mozilla-key"
echo -e "  > ${actualMozillaKey} = actual-mozilla-key"

if [[ "${actualMozillaKey}" == "${expectedMozillaKey}" ]]; then
echo -e "${greenbold} ✅ The key fingerprint matches${normal}"
else
echo -e "${redbold} ⚠️ WARNING: unexpected fingerprint${normal}\n"
exit 103
fi

echo -e "\n${bluebold}  Create /etc/apt/sources.list.d/mozilla.sources${normal}\n"
echo "\
# Mozilla apt package repository
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Architectures: amd64 arm64
Signed-By: /usr/share/keyrings/mozilla-archive-keyring.asc\
" | sudo tee /etc/apt/sources.list.d/mozilla.sources

echo -e "\n${cyanbold}Install firefox-devedition${normal}"
echo -e "$ sudo apt-get update && sudo apt-get install firefox-devedition \
firefox-devedition-l10n-en-gb libpci3 libegl1\n"
sudo apt-get update && sudo apt-get install firefox-devedition \
firefox-devedition-l10n-en-gb libpci3 libegl1

# mark that packages have changed
pkgchanges=1

echo -e "\n${redbold}Restart needed to prevent firefox errors about \
org.a11y.Bus${normal}"
echo "please run:"
echo "wsl.exe --shutdown"

fi

# Check for presence of lynx

lynxcheck=$(lynx -version  2> /dev/null | head -c 4)
if [[ "${lynxcheck}" != "Lynx" ]]; then
echo -e "\n${cyanbold}Installing lynx${normal}"
echo -e "$ sudo apt update && sudo apt -y install lynx\n"
sudo apt update && sudo apt -y install lynx
# mark that packages have changed
pkgchanges=1
fi

# Get latest 1password versions

echo -e "\n${cyanbold}Latest status message for 1password linux stable${normal}"
longversion1p=$(lynx -dump https://releases.1password.com/linux/stable \
| grep -oE "Updated\sto.*$")
shortversion1p=$(echo -e "${longversion1p}" | grep -oE "[0-9]+\.[0-9\.]+")
echo -e "> ${longversion1p}"

# ################## #
# ON AMD64 ARCH ONLY #
# ################## #
if [[ "${pkgarch}" == "amd64" ]]; then

# Install 1password deb repo (on amd64 arch only)

echo -e "amd64" # placeholder



# ###################### #
# END AMD64 ONLY SECTION #
# ###################### #
fi

# ################## #
# ON ARM64 ARCH ONLY #
# ################## #
if [[ "${pkgarch}" == "arm64" ]]; then

# Explicitly install 1password dependencies

echo -e "\n${cyanbold}Explicitly install 1password dependencies${normal}"
echo -e "${cyanbold}( this dependency list was extracted from deb file in \
Oct-2025 )${normal}"
echo -e "${cyanbold}( https://downloads.1password.com/linux/debian/amd64/stable\
/1password-latest.deb )${normal}"
echo -e "
sudo apt install \\
curl \\
gnupg2 \\
libasound2 \\
libatk-bridge2.0-0 \\
libatk1.0-0 \\
libc6 \\
libcurl4 \\
libdrm2 \\
libgbm1 \\
libgtk-3-0 \\
libnotify4 \\
libnss3 \\
libxcb-shape0 \\
libxcb-xfixes0 \\
libxshmfence1 \\
libudev1 \\
xdg-utils \\
libappindicator3-1\
\n"
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

# mark that packages have changed
pkgchanges=1

# Make folder(s) if they don't exist

echo -e "\n${cyanbold}Build our own deb package for arm64 arch${normal}"
echo -e "$ mkdir -p ~/git/${github_username}/${github_project}/pkgbuild"
mkdir -p "${HOME}/git/${github_username}/${github_project}/pkgbuild"

# Navigate to working directory

echo -e "$ cd ~/git/${github_username}/${github_project}/pkgbuild"
cd "${HOME}/git/${github_username}/${github_project}/pkgbuild" 2> /dev/null \
|| { echo -e "${redbold}> Failed to change directory, exiting${normal}\n"\
; exit 104; }

# get latest 1password amd64 deb package

echo -e "\n${cyanbold}Get latest 1password amd64 deb package${normal}"
echo -e "$ wget -O 1password_${shortversion1p}_amd64.deb \
https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb"
echo -e "\n"
wget -O "1password_${shortversion1p}_amd64.deb" \
https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb

# TO-DO: Complete manual deb package build here

# ###################### #
# END ARM64 ONLY SECTION #
# ###################### #
fi

# tidy up apt again if package changes have occurred

if [[ "${pkgchanges}" -eq 1 ]]; then
echo -e "\n${bluebold}Packages have changed - clean up again${normal}"
echo -e "\n${cyanbold}Make autoremove work properly${normal}"
echo -e "$ sudo apt-mark minimize-manual -y\n"
sudo apt-mark minimize-manual -y
echo -e "\n${cyanbold}Clean up packages${normal}"
echo -e "$ sudo apt autoremove --purge\n"
sudo apt autoremove --purge
fi

# Log this latest `Config` operation and display runtime

echo -e "\n${bluebold}${filename} run at${normal}"
echo -e "> ${runtime}\n"
mkdir -p "${HOME}/git/${github_username}/${github_project}"
echo -e "FILE: ${filename} | EXEC-TIME: ${runtime}" \
>> "${HOME}/git/${github_username}/${github_project}/config-runs.log"

################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

