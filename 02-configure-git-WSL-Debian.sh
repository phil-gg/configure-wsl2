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
exit 101

else

echo -e "${greenbold}> Account(s) registered in 1password-cli${normal}\n"
echo -e "$ op account list\n"
op account list
echo -e "\n${cyanbold}Checking whether logged into 1password-cli${normal}"

opclicheck2=$(op vault list 2>&1 | grep -o ERROR)

if [[ "${opclicheck2}" == "ERROR" ]]; then
echo -e "${redbold}> Not logged into 1password-cli${normal}

RUN THIS NEXT:

eval \$(op signin)

…then re-run this script.
"
exit 102
else
echo -e "${greenbold}> Logged into 1password-cli${normal}"
fi

fi

# Set sensitive variables

#  TO-DO: Add variables

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
exit 103
else
echo "${greenbold}> Online${normal}"
fi

# Now running `${filename}`

echo -e "\n${bluebold}Now running ‘${filename}’${normal}"

# Make folder(s) if they don't exist

echo -e "$ mkdir -p ~/git/${github_username}/${github_project}"
mkdir -p "${HOME}/git/${github_username}/${github_project}"

# Navigate to working directory

echo -e "$ cd ~/git/${github_username}/${github_project}"
cd "${HOME}/git/${github_username}/${github_project}" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 104; }

# Check for presence of git & gh

gitcheck=$(git -v  2> /dev/null | head -c3)
ghcheck=$(gh --version 2> /dev/null | head -c2)
if [[ "${gitcheck}" != "git" || "${ghcheck}" != "gh" ]]; then
echo -e "\n${cyanbold}Installing git and/or gh${normal}"
# include man-db so that e.g. "git config --help" works
echo -e "$ sudo apt update && sudo apt -y install git-all gh man-db\n"
sudo apt update && sudo apt -y install git-all gh man-db
fi

# Check for presence of git config

maincheck=$(git config --list 2> /dev/null | grep "init.defaultbranch=main")
if [ "${maincheck}" != "init.defaultbranch=main" ];
then
echo -e "\n$ git config --global init.defaultbranch main"
git config --global init.defaultbranch main
fi

# TO-DO: more config here
# git config --global user.name "John Doe"
# git config --global user.email johndoe@example.com
# authorise git with gh

# Sync project to working directory with git

echo -e "\n${cyanbold}Sync project with github${normal}"

git fetch &> /dev/null

if [ $? -eq 128 ]; then

echo -e "> .git not created yet\n"
echo -e "$ git init\n"
git init

echo -e "\n$ git remote add origin \
https://github.com\
/${github_username}\
/${github_project}.git\
${normal}\n"
git remote add origin "https://github.com\
/${github_username}\
/${github_project}.git"

echo -e "$ git fetch\n"
git fetch

echo -e "\n$ git checkout main -f\n"
git checkout main -f

echo -e "\n$ git branch --set-upstream-to origin/${github_branch}\n"
git branch --set-upstream-to "origin/${github_branch}"

fi

echo -e "\n$ git status\n"
status=$(git status)
echo -e "${status}"

# TODO-1: git pull if status check says it is needed
# TODO-2: git push if status check says it is needed
# TODO-3: print visible git status output once pull and/or push done



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
