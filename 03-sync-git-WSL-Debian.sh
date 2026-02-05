#!/bin/bash

################################################################################
# Synchronise git with configure-wsl2 Debian project, in an idempotent manner.
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
filename="03-sync-git-WSL-Debian.sh"
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

# Connect with GitHub and check status

echo -e "\n${cyanbold}Connect with GitHub and check status${normal}"

# Clone if no .git folder
if [ ! -d ".git" ]; then
echo -e "> .git not created yet"

# Clone only works with empty directory: can't have e.g. config-runs.log here
find "${HOME}/git/${github_username}/${github_project}" -mindepth 1 -delete

# final dot prevents a duplicate ${github_project} folder
# clone replaced remote add
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
exit 102
fi

# Show git status, and put porcelain status into a variable
echo -e "\n$ git status\n"
STATUS=$(git status -b --porcelain)
git status

# Log this latest `Config` operation and display runtime

echo -e "\n${bluebold}${filename} run at${normal}"
echo -e "> ${runtime}"
mkdir -p "${HOME}/git/${github_username}/${github_project}"
echo -e "FILE: ${filename} | EXEC-TIME: ${runtime}" \
>> "${HOME}/git/${github_username}/${github_project}/config-runs.log"

# If git is up-to-date, end the script here (no sync actions needed)
FILES_DIFF=$(git status --porcelain)
# shellcheck disable=SC1083
COMMIT_DIFF=$(git rev-list HEAD..@{u} --count)
if [[ -z "${FILES_DIFF}" ]] && [[ "${COMMIT_DIFF}" -eq 0 ]]; then
echo -e "${greenbold}> Everything is up to date, exiting${normal}\n"
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
echo -e "\n${greenbold}> Sync complete${normal}\n"

################################################################################
#
# Line wrap ruler
#
#   5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80
#
################################################################################

