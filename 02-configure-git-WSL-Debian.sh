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

opclicheck2=$(op vault list 2>&1 | grep -o ERROR)

if [[ "${opclicheck2}" == "ERROR" ]]; then
echo -e "${redbold}> Not logged into 1password-cli${normal}

RUN THIS NEXT:

eval \$(op signin)

…then re-run this script.
"
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

# Now running `${filename}`

echo -e "\n${bluebold}Now running ‘${filename}’${normal}"

# Make folder(s) if they don't exist

echo -e "$ mkdir -p ~/git/${github_username}/${github_project}"
mkdir -p "${HOME}/git/${github_username}/${github_project}"

# Navigate to working directory

echo -e "$ cd ~/git/${github_username}/${github_project}"
cd "${HOME}/git/${github_username}/${github_project}" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}\n"\
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

# Verify gh auth login

echo -e "\n${cyanbold}Verify gh auth login${normal}"
echo -e "\n$ gh auth status\n"
gh auth status
# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
echo -e "\n${redbold}> Failed to authenticate GitHub CLI, exiting${normal}\n"
exit 105
fi

# Connect with GitHub and check status

echo -e "\n${cyanbold}Connect with GitHub and check status${normal}"

# Clone if no .git folder
if [ ! -d ".git" ]; then
echo -e "> .git not created yet"

# final dot prevents a duplicate ${github_project} folder
# clone replaced remote add, which 
echo -e "\n$ git clone \
\"https://github.com\
/${github_username}\
/${github_project}.git\" .\n"
git clone "https://github.com/${github_username}/${github_project}.git" .

# force move HEAD (current position) to latest commit in main
# likely redundant as clone already put HEAD at end of default branch
echo -e "\n$ git checkout \"${github_branch}\" -f\n"
git checkout "${github_branch}" -f

# reset --hard synchronises local files to the remote branch state
# likely redundant as clone probably already updated files this way
echo -e "\n$ git reset --hard \"origin/${github_branch}\"\n"
git reset --hard "origin/${github_branch}"

fi

# First connect and get remote updates (if .git existed)
echo -e "\n$ git fetch -v\n"
git fetch -v
# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
echo -e "\n${redbold}> Failed to fetch project from GitHub, exiting${normal}\n"
exit 106
fi

# Show git status, and put porcelain status into a variable
echo -e "\n$ git status\n"
STATUS=$(git status -b --porcelain)
git status

# Log this latest `Config` operation and display runtime

echo -e "\n${bluebold}${filename} run at${normal}"
echo -e "> ${runtime}\n"
mkdir -p "${HOME}/git/${github_username}/${github_project}"
echo -e "FILE: ${filename} | EXEC-TIME: ${runtime}" \
>> "${HOME}/git/${github_username}/${github_project}/config-runs.log"

# If git is up-to-date, end the script here (no sync actions needed)
# shellcheck disable=SC1083
REMOTE_DIFF=$(git rev-list HEAD..@{u} --count)
if [[ -z "${STATUS}" ]] && [[ "${REMOTE_DIFF}" -eq 0 ]]; then
echo -e "\n${greenbold}> Everything is up to date, exiting${normal}\n"
exit 0
fi

# Sync present working directory to project remote with git

echo -e "\n${cyanbold}Sync project with github${normal}"

# Add wholly new (untracked) files
# The porcelain check '??' identifies untracked files
if [[ "${STATUS}" == *"??"* ]]; then
echo -e "\n> New untracked files detected"
echo -e "\n$ git add .\n"
git add .
# Refresh STATUS so the commit message reflects the added state
STATUS=$(git status -b --porcelain)
fi

# Commit modifications if the repository is dirty
if ! git diff --quiet || ! git diff --cached --quiet; then

echo -e "\n> Modified, uncommitted files detected"

# Create commit message
FILE_COUNT=$(echo "$STATUS" | wc -l)
if [ "${FILE_COUNT}" -gt 3 ]; then
COMMIT_MESSAGE="Update ${FILE_COUNT} files"
else
COMMIT_MESSAGE="$(echo "${STATUS}" | tr '\n' '' | xargs)"
fi

echo -e "\n> COMMIT_MESSAGE=\"${COMMIT_MESSAGE}\""

echo -e "\n$ git commit -a -m \"\${COMMIT_MESSAGE}\"\n"
git commit -a -m "${COMMIT_MESSAGE}"

# Refresh STATUS so the commit message reflects the committed state
STATUS=$(git status -b --porcelain)

fi

# Pull where necessary
# Rebase puts any local changes on top of the remote changes (where possible)
if [[ "${STATUS}" == *"behind"* ]]; then
echo -e "\n> Pull changes from remote"
echo -e "\n$ git pull --rebase\n"
git pull --rebase
# Refresh STATUS so the commit message reflects the pulled state
STATUS=$(git status -b --porcelain)
fi

# Push where necessary
if [[ "${STATUS}" == *"ahead"* ]]; then
echo -e "\n> Push local changes to remote"
echo -e "\n$ git push\n"
git push
fi

# If you have made it here, and not exited above, you need status one last time
echo -e "\n$ git status\n"
git status



################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

