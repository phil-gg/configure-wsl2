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

# Set non-sensitive variables
# NOTE: Sensitive variables are further below

github_username="phil-gg"
github_project="configure-wsl2"
github_branch="main"
filename="02-configure-git-WSL-Debian.sh"
runtime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
normal=$(printf '\033[0m')
redbold=$(printf '\033[91;1m')
greenbold=$(printf '\033[92;1m')
cyanbold=$(printf '\033[96;1m')
bluebold=$(printf '\033[94;1m')

# Now running `${filename}`

echo -e "\n${bluebold}Now running ‘${filename}’${normal}"

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
echo -e "${redbold}> Offline${normal}\n"
exit 101
else
echo -e "${greenbold}> Online${normal}"
fi

# Ensure 1password-cli can set sensitive variables

echo -e "\n${cyanbold}Checking whether account registered in 1password-cli\
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
exit 102

else

echo -e "${greenbold}> Account(s) registered in 1password-cli${normal}\n"
echo -e "$ op account list\n"
op account list
echo -e "\n${cyanbold}Checking whether logged into 1password-cli${normal}"

if ! op account get &> /dev/null; then
echo -e "${redbold}> Not logged into 1password-cli${normal}\n
RUN THIS NEXT:\n
eval \$(op signin)\n
…then re-run this script.\n"
exit 103
else
echo -e "${greenbold}> Logged into 1password-cli${normal}"
fi

fi

# Set sensitive variables

echo -e "\n${cyanbold}Read secrets from 1password-cli${normal}"

GH_TOKEN=$(op read "op://\
sgsub5ksyk2khnrzflt4pyziru/\
z7x5d5r2hdnytyuulwq57lsixa/\
ucz4cqku2w7ctc3yseteme2boe")

echo -e "> GH_TOKEN=$(echo \
"${GH_TOKEN}" | head -c8)…\
$(echo "${GH_TOKEN}" | tail -c5)"

GH_EMAIL=$(op read "op://\
sgsub5ksyk2khnrzflt4pyziru/\
z7x5d5r2hdnytyuulwq57lsixa/\
4w3e6rvo5yag5muvhg3tm5oofi")

echo -e "> GH_EMAIL=${GH_EMAIL}"

GH_USERN=$(op read "op://\
sgsub5ksyk2khnrzflt4pyziru/\
z7x5d5r2hdnytyuulwq57lsixa/\
username")

echo -e "> GH_USERN=${GH_USERN}"

# Make folder(s) if they don't exist

if [ ! -d "${HOME}/git/${github_username}/${github_project}/" ]; then
echo -e "$ mkdir -p ~/git/${github_username}/${github_project}"
mkdir -p "${HOME}/git/${github_username}/${github_project}/"
fi

# Navigate to working directory

echo -e "$ cd ~/git/${github_username}/${github_project}"
cd "${HOME}/git/${github_username}/${github_project}" 2> /dev/null \
|| { echo -e "${redbold}> Failed to change directory, exiting${normal}\n"\
; exit 104; }

# Check for presence of git & gh

if ! command -v git &> /dev/null \
|| ! command -v gh &> /dev/null; then
echo -e "\n${cyanbold}Installing git and/or gh${normal}"
# include man-db so that e.g. "git config --help" works
echo -e "$ sudo apt update && sudo apt -y install \
git \
git-doc \
git-gui \
gitk \
gh \
man-db\n"
sudo apt update && sudo apt -y install \
git \
git-doc \
git-gui \
gitk \
gh \
man-db
fi

# Check for presence of git config

echo -e "\n${cyanbold}git config checks${normal}"

branchcheck=$(git config --global init.defaultbranch)
branchvalue="main"
if [ "${branchcheck}" != "${branchvalue}" ];
then
echo -e "\n$ git config --global init.defaultbranch ${branchvalue}"
git config --global init.defaultbranch ${branchvalue}
fi

emailcheck=$(git config --global user.email)
if [ "${emailcheck}" != "${GH_EMAIL}" ];
then
echo -e "\n$ git config --global user.email \"${GH_EMAIL}\""
git config --global user.email "${GH_EMAIL}"
fi

userncheck=$(git config --global user.name)
if [ "${userncheck}" != "${GH_USERN}" ];
then
echo -e "\n$ git config --global user.name \"${GH_USERN}\""
git config --global user.name "${GH_USERN}"
fi

authcheck=$(git config --list | grep -oF "/usr/bin/gh" | sort -u)
authvalue="/usr/bin/gh"
if [ "${authcheck}" != "${authvalue}" ];
then
echo -e "\n$ echo \"\${GH_TOKEN}\" | gh auth login --with-token --hostname \
github.com && gh auth setup-git"
echo "${GH_TOKEN}" | gh auth login --with-token --hostname github.com && \
gh auth setup-git
fi

echo -e "\n$ git config --list\n"
git config --list

# Log this latest `Config` operation and display runtime

echo -e "\n${bluebold}${filename} run at${normal}"
echo -e "> ${runtime}"
mkdir -p "${HOME}/git/${github_username}/${github_project}"
echo -e "FILE: ${filename} | EXEC-TIME: ${runtime}" \
>> "${HOME}/git/${github_username}/${github_project}/config-runs.log"

# Verify gh auth login

echo -e "\n${cyanbold}Verify gh auth login${normal}"
echo -e "\n$ gh auth status\n"
gh auth status
# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
echo -e "\n${redbold}> Failed to authenticate GitHub CLI, exiting${normal}\n"
exit 105
else
echo -e "\n${greenbold}> git & gh configured with GitHub credentials${normal}\n
Run ‘03-sync-git-WSL-Debian.sh’ next\n"
fi

################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

