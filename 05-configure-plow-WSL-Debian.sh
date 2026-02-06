#!/bin/bash

################################################################################
# Configure a {wslg > weston > kde-plasma} nested desktop environment, in an
# idempotent manner.
# I'm calling this nested monstrosity 'plow', short for Plasma on WSLg.
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
filename="05-configure-plow-WSL-Debian.sh"
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

# Make folder(s) if they don't exist

if [ ! -d "${HOME}/git/${github_username}/${github_project}" ]; then
echo -e "\n$ mkdir -p ~/git/${github_username}/${github_project}"
mkdir -p "${HOME}/git/${github_username}/${github_project}"
fi

# Navigate to working directory

echo -e "\n$ cd ~/git/${github_username}/${github_project}"
cd "${HOME}/git/${github_username}/${github_project}" 2> /dev/null \
|| { echo -e "${redbold}> Failed to change directory, exiting${normal}\n"\
; exit 102; }

# Create ~/.config/weston.ini if it does not exist or has changed

if [ ! -f "${HOME}/.config/weston.ini" ] || \
! cmp -s HOME/.config/weston.ini "${HOME}/.config/weston.ini"; then
echo -e "\n${cyanbold}Updating ~/.config/weston.ini${normal}"
echo -e "$ cp -f HOME/.config/weston.ini ~/.config/weston.ini"
cp -f HOME/.config/weston.ini "${HOME}/.config/weston.ini"
fi

# Packages for {wslg > weston > kde-plasma} nested desktop environment

PACKAGES="\
weston \
mesa-utils \
plasma-workspace \
kde-cli-tools \
kio-extras \
kio-fuse \
ksystemstats \
plasma-workspace-doc \
systemsettings \
plasma-desktop \
breeze-gtk-theme \
kde-config-gtk-style \
fonts-hack \
fonts-noto \
fonts-noto-color-emoji \
khelpcenter \
kinfocenter \
kwin-wayland"

# shellcheck disable=SC2086
DPKG_OUTPUT=$(dpkg -l ${PACKAGES} 2> /dev/null)
DPKG_ERROR=$?
START_LINE=$(echo "$DPKG_OUTPUT" | awk '/^\+\+\+-=/ {print NR + 1; exit}')
# shellcheck disable=SC2086
DPKG_TAIL=$(echo "${DPKG_OUTPUT}" | tail -n +${START_LINE})
NON_II_CODES=$(echo "${DPKG_TAIL}" | awk '!/^ii/ {print substr($0, 1, 2)}')

if [ -n "${NON_II_CODES}" ] || [ "${DPKG_ERROR}" -ne 0 ]; then
echo -e "\n${cyanbold}Installing packages${normal}"
echo -e "$ sudo apt update && sudo apt install -y ${PACKAGES}"
# shellcheck disable=SC2086
sudo apt update && sudo apt install -y ${PACKAGES}
fi

# Kernel module vgem required as DRM buffer for d3d12 driver

if [ ! -f /etc/modules-load.d/vgem.conf ]; then
echo -e "\n${cyanbold}Load vgem on every future boot${normal}"
echo -e "$ echo -e \"vgem\\\n\" &> /dev/null | sudo tee /etc/modules-load.d/\
vgem.conf"
echo -e "vgem\n" | sudo tee /etc/modules-load.d/vgem.conf &> /dev/null
fi

if ! lsmod | grep -q vgem; then
echo -e "\n${cyanbold}Load vgem now${normal}"
echo -e "$ sudo modprobe vgem"
sudo modprobe vgem
fi

echo -e "\n${cyanbold}Show loaded vgem (and related) kernel modules${normal}"
echo -e "echo -e $ \"\$(lsmod | head -n 1)\\\n\$(lsmod | grep vgem)\"\n"
echo -e "$(lsmod | head -n 1)\n$(lsmod | grep vgem)"

echo -e "\n${cyanbold}Show vgem (and related) kernel modules${normal}"
echo -e "$ ls -l /dev/dri\n"
ls -l /dev/dri
echo -e "\n$ ls -l /dev/dri/by-path\n"
ls -l /dev/dri/by-path

echo -e "\n${cyanbold}Show glxinfo using Nvidia graphics through d3d12 driver\
${normal}"
echo -e "\
$ GALLIUM_DRIVER=d3d12 \\\\
  MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA \\\\
  glxinfo -B\n"
GALLIUM_DRIVER=d3d12 \
MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA \
glxinfo -B

# Set up virtual screen on Weston, in the background (final ampersand)

echo -e "\n${cyanbold}Set up virtual screen on Weston with name weston${normal}"
echo -e "$ weston --socket=weston > /dev/null 2>&1 &"
weston --socket=weston > /dev/null 2>&1 &
echo -e "$ ls /run/user/\$(id -u)/weston"
ls /run/user/$(id -u)/weston

echo -e "\n${bluebold}Run weston with log output to terminal for \
troubleshooting${normal}"
echo -e "${cyanbold}weston --socket=weston${normal}"

echo -e "\n${bluebold}End weston session${normal}"
echo -e "${cyanbold}pkill -f \"weston --socket=weston\"${normal}"

# Run kde-plasma in weston

echo -e "\n${cyanbold}Run KDE Plasma in weston${normal}"
echo -e "\
$ WAYLAND_DISPLAY=weston \
  GALLIUM_DRIVER=d3d12 \
  MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA \
  dbus-run-session startplasma-wayland > /dev/null 2>&1 &"
WAYLAND_DISPLAY=weston \
GALLIUM_DRIVER=d3d12 \
MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA \
dbus-run-session startplasma-wayland > /dev/null 2>&1 &

echo -e "\n${bluebold}Run KDE Plasma with log output to (second) terminal \
(separate from weston)${normal}"
echo -e "${cyanbold}\
WAYLAND_DISPLAY=weston \\\\
GALLIUM_DRIVER=d3d12 \\\\
MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA \\\\
dbus-run-session startplasma-wayland
${normal}"

# TO-DO: More config here

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

