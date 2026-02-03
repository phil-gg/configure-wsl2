#!/bin/bash

################################################################################
# Configure Locale Keyboard & Timezone on WSL Debian in an idempotent manner.
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
filename="03-locale-keyboard-timezone-WSL-Debian.sh"
runtime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
normal=$(printf '\033[0m')
redbold=$(printf '\033[91;1m')
greenbold=$(printf '\033[92;1m')
cyanbold=$(printf '\033[96;1m')
bluebold=$(printf '\033[94;1m')
changes_made="0"

# Now running `${filename}`

echo -e "\n${cyanbold}Now running ‘${filename}’${normal}"

# Navigate to working directory

echo -e "$ cd ~/git/${github_username}/${github_project}"
cd "${HOME}/git/${github_username}/${github_project}" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 101; }

# Locale configuration

if [[ ! -f /usr/share/i18n/locales/en_AU@phil ]]; then
echo -e "\n${cyanbold}Installing custom locale${normal}"
echo -e "$ sudo cp usr/share/i18n/locales/en_AU@phil /usr/share/i18n/locales/en_AU@phil"
sudo cp usr/share/i18n/locales/en_AU@phil /usr/share/i18n/locales/en_AU@phil
changes_made="1"
fi

if ! cmp -s usr/share/i18n/SUPPORTED /usr/share/i18n/SUPPORTED; then
echo -e "\n${cyanbold}Updating SUPPORTED locales${normal}"
echo -e "$ sudo cp -f usr/share/i18n/SUPPORTED /usr/share/i18n/SUPPORTED"
sudo cp -f usr/share/i18n/SUPPORTED /usr/share/i18n/SUPPORTED
changes_made="1"
fi

if ! cmp -s etc/locale.gen /etc/locale.gen; then
echo -e "\n${cyanbold}Updating /etc/locale.gen${normal}"
echo -e "$ sudo cp -f etc/locale.gen /etc/locale.gen"
sudo cp -f etc/locale.gen /etc/locale.gen
changes_made="1"
fi

if ! cmp -s etc/locale.conf /etc/locale.conf; then
echo -e "\n${cyanbold}Updating /etc/locale.conf${normal}"
echo -e "$ sudo cp -f etc/locale.conf /etc/locale.conf"
sudo cp -f etc/locale.conf /etc/locale.conf
changes_made="1"
fi

if [[ "${changes_made}" == "1" ]]; then
echo -e "\n${cyanbold}Running locale-gen${normal}"
echo -e "$ sudo locale-gen"
sudo locale-gen
echo -e "\n${redbold}Locale updated but restart required${normal}\n
Please run:\n
wsl.exe --shutdown"
fi

# Keyboard configuration



# Log this latest `Config` operation and display runtime

echo -e "FILE: ${filename} | EXEC-TIME: ${runtime}" >> config-runs.log
echo -e "\n${bluebold}${filename} run at${normal}"
echo -e "  ${runtime}\n"

################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################
