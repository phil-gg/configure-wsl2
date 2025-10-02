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
filename="02-configure-git-WSL-Debian.sh"
runtime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
normal=$(printf '\033[0m')
redbold=$(printf '\033[91;1m')
greenbold=$(printf '\033[92;1m')
cyanbold=$(printf '\033[96;1m')
bluebold=$(printf '\033[94;1m')

# Now running `${filename}`

echo -e "\n${cyanbold}Now running ‘${filename}’${normal}"

# Make folder(s) if they don't exist

echo -e "$ mkdir -p ~/git/${github_username}/${github_project}"
mkdir -p "${HOME}/git/${github_username}/${github_project}"

# Navigate to working directory

echo -e "$ cd ~/git/${github_username}/${github_project}"
cd "${HOME}/git/${github_username}/${github_project}" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 101; }

# Network test

echo -e "\n${bluebold}Testing network connectivity${normal}"
echo -e "  Test file https://raw.githubusercontent.com\
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

# Check for presence of git

gitcheck=$(git -v  2> /dev/null | cut -c1-3)
if [ "${gitcheck}" != "git" ]; then
echo -e "\n${cyanbold}Installing git${normal}"
echo -e "$ sudo apt update && sudo apt install git\n"
sudo apt update && sudo apt install git
fi

# Check for presence of git config

if ! git config --list | grep "init.defaultbranch=main" 1> /dev/null
then
git config --global init.defaultbranch main
fi

# Sync project to working directory with git

echo -e "\n${cyanbold}Sync project with github${normal}"

git fetch &> /dev/null

if [ $? -eq 128 ]; then
echo "  .git not created yet"

echo -e "\n${cyanbold}git init${normal}"
git init

echo -e "\n${cyanbold}git remote add origin ${normal}\
https://github.com\
/${github_username}\
/${github_project}.git\
${normal}"
git remote add origin "https://github.com\
/${github_username}\
/${github_project}.git"

echo -e "\n${cyanbold}git fetch${normal}"
git fetch

echo -e "\n${cyanbold}git checkout main -f${normal}"
git checkout main -f

echo -e "\n${cyanbold}git branch --set-upstream-to \
origin/${github_branch}${normal}"
git branch --set-upstream-to "origin/${github_branch}"

echo -e "\n${cyanbold}git status${normal}"
git status

else

git status # &> /dev/null

fi

# TODO-1: git pull if silenced status check says it is needed
# TODO-2: git push if silenced status check says it is needed
# TODO-3: print visible git status output once pull and/or push don



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
