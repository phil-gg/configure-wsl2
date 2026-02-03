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

# Test locale if no changes made this run
if [[ "${changes_made}" == "0" ]]; then

# Check for presence of python3
if ! command -v python3 &> /dev/null; then
echo -e "\n${cyanbold}Installing python3${normal}"
echo -e "$ sudo apt update && sudo apt -y install python3\n"
sudo apt update && sudo apt -y install python3
fi

echo -e "\n${cyanbold}Testing locale configuration${normal}"
echo -e "$ locale\n"
locale

echo -e "\n$ localectl status\n"
localectl status

echo -e "\n$ locale -k LC_NUMERIC\n"
locale -k LC_NUMERIC

echo -e "\n$ date"
date
echo -e "${greenbold}> DESIRED OUTPUT:
DDD-DD-MMM-YYYY HH:MM:SS TZ${normal}"

echo -e "\n$ awk 'BEGIN { printf \"%'\"'\"'.4f\\\n\", 1234567.89 }'"
awk 'BEGIN { printf "%'"'"'.4f\n", 1234567.89 }'
echo -e "${greenbold}> DESIRED OUTPUT:
1 234 567.8900${normal}"

echo -e "\n$ python3 -c \"import locale; locale.setlocale(locale.LC_ALL, ''); \
print(locale.currency(1234567.891, grouping=True))\""
python3 -c "import locale; locale.setlocale(locale.LC_ALL, ''); \
print(locale.currency(1234567.891, grouping=True))"
echo -e "${greenbold}> DESIRED OUTPUT:
 + $ 1 234 567.89${normal}"

echo -e "\n$ python3 -c \"import locale; locale.setlocale(locale.LC_ALL, ''); \
print(locale.currency(1234567.891, grouping=True, international=True))\""
python3 -c "import locale; locale.setlocale(locale.LC_ALL, ''); \
print(locale.currency(1234567.891, grouping=True, international=True))"
echo -e "${greenbold}> DESIRED OUTPUT:
 + AUD 1 234 567.89${normal}"

echo -e "\n$ python3 -c \"import locale; locale.setlocale(locale.LC_ALL, ''); \
print(locale.currency(-1234567.891, grouping=True))\""
python3 -c "import locale; locale.setlocale(locale.LC_ALL, ''); \
print(locale.currency(-1234567.891, grouping=True))"
echo -e "${greenbold}> DESIRED OUTPUT:
 - $ 1 234 567.89${normal}"

echo -e "\n$ python3 -c \"import locale; locale.setlocale(locale.LC_ALL, ''); \
print(locale.currency(-1234567.891, grouping=True, international=True))\""
python3 -c "import locale; locale.setlocale(locale.LC_ALL, ''); \
print(locale.currency(-1234567.891, grouping=True, international=True))"
echo -e "${greenbold}> DESIRED OUTPUT:
 - AUD 1 234 567.89${normal}"

fi

# Keyboard configuration

if ! localectl list-keymaps &> /dev/null; then

echo -e "\n${cyanbold}Installing keymaps${normal}"
kbd_version=$(lynx -dump https://github.com/legionus/kbd/releases/latest | \
grep -E "^v[0-9.]+$" | head -n 1 | cut -c 2-)

echo -e "\n$ mkdir -p ~/git/${github_username}/${github_project}/tmp"
mkdir -p "${HOME}/git/${github_username}/${github_project}/tmp"

echo -e "\n$ cd ~/git/${github_username}/${github_project}/tmp"
cd "${HOME}/git/${github_username}/${github_project}/tmp" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 102; }

echo -e "\n$ wget https://github.com/legionus/kbd/releases/download/\
v${kbd_version}/kbd-${kbd_version}.tar.xz -O kbd-${kbd_version}.tar.xz\n"
wget "https://github.com/legionus/kbd/releases/download/v${kbd_version}/\
kbd-${kbd_version}.tar.xz" -O "kbd-${kbd_version}.tar.xz"

echo -e "$ tar -xf kbd-${kbd_version}.tar.xz"
tar -xf "kbd-${kbd_version}.tar.xz"

echo -e "$ sudo cp -Rp kbd-${kbd_version}/data/keymaps/* /usr/share/keymaps/"
# shellcheck disable=SC2086
sudo cp -Rp kbd-${kbd_version}/data/keymaps/* /usr/share/keymaps/

echo -e "$ cd ~/git/${github_username}/${github_project}"
cd "${HOME}/git/${github_username}/${github_project}" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 103; }

echo -e "$ rm -rf ~/git/${github_username}/${github_project}/tmp"
# rm -rf "${HOME}/git/${github_username}/${github_project}/tmp"

fi

echo -e "$ localectl list-keymaps"
localectl list-keymaps



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
