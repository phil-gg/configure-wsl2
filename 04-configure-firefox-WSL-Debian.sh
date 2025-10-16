#!/bin/bash

################################################################################
# Configure Firefox on WSL Debian in an idempotent manner.
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
filename="04-configure-firefox-WSL-Debian.sh"
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
echo -e "${redbold}> Offline${normal}"
exit 101
else
echo -e "${greenbold}> Online${normal}"
fi

# Navigate to working directory

echo -e "$ cd ~/git/${github_username}/${github_project}/pkgbuild"
cd "${HOME}/git/${github_username}/${github_project}/pkgbuild" 2> /dev/null \
|| { echo -e "${redbold}> Failed to change directory, exiting${normal}\n"\
; exit 102; }

# Ensure 1password-cli is logged in for secrets

echo -e "${cyanbold}Checking whether account registered in 1password-cli\
${normal}"
opclicheck1=$(op account list | grep -o "1password.com" 2> /dev/null)
if [[ "${opclicheck1}" != "1password.com" ]]; then
echo -e "${redbold}> No accounts registered in 1password-cli${normal}
> sign-in address = my.1password.com
>  email  address = p… .c…@gmail.com
>   For secret key:
>    Open https://my.1password.com/apps
>    …and click ‘Sign in manually’ button
> Next enter master password
> Finally enter TOTP from another 1password instance

RUN THIS NEXT:

eval \$(op account add --signin)
"
else
echo -e "${greenbold}> Account(s) registered in 1password-cli${normal}\n"
op account list
echo -e "\n${cyanbold}Checking whether logged into 1password-cli${normal}"

opclicheck2=$(op vault list 2>&1 | grep -o ERROR)

if [[ "${opclicheck2}" == "ERROR" ]]; then
echo -e "${redbold}> Not logged into 1password-cli${normal}

RUN THIS NEXT:

eval \$(op signin)
"
else
echo -e "${greenbold}> Logged into 1password-cli${normal}\n"
exit 103
fi

fi

# Configure firefox

# TO-DO: Configuration here

################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

# Log this latest `Config` operation and display runtime

echo -e "\n${bluebold}${filename} run at${normal}"
echo -e "> ${runtime}\n"
mkdir -p "${HOME}/git/${github_username}/${github_project}"
echo -e "FILE: ${filename} | EXEC-TIME: ${runtime}" \
>> "${HOME}/git/${github_username}/${github_project}/config-runs.log"

