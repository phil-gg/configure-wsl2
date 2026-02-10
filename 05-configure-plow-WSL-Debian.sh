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
UNITS_CHANGED=0

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

# Create /etc/xdg/weston/weston.ini if it does not exist or has changed

if [ ! -f /etc/xdg/weston/weston.ini ] || \
! cmp -s etc/xdg/weston/weston.ini /etc/xdg/weston/weston.ini; then
echo -e "\n${cyanbold}Configure weston${normal}"
echo -e "$ sudo mkdir -p /etc/xdg/weston"
sudo mkdir -p /etc/xdg/weston
echo -e "$ sudo cp -f etc/xdg/weston/weston.ini /etc/xdg/weston/weston.ini"
sudo cp -f etc/xdg/weston/weston.ini /etc/xdg/weston/weston.ini
echo -e "$ ln -sf /etc/xdg/weston/weston.ini ~/.config/weston.ini"
ln -sf /etc/xdg/weston/weston.ini "${HOME}/.config/weston.ini"
fi

# Always run sudo apt update

echo -e "\n${cyanbold}Update apt then check for required packages${normal}"
echo -e "$ sudo apt update"
sudo apt update

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
konsole \
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
if [ "${DPKG_ERROR}" -eq 0 ]; then
START_LINE=$(echo "$DPKG_OUTPUT" | awk '/^\+\+\+-=/ {print NR + 1; exit}')
# shellcheck disable=SC2086
DPKG_TAIL=$(echo "${DPKG_OUTPUT}" | tail -n +${START_LINE})
APT_REQD=$(echo "${DPKG_TAIL}" | awk '!/^(ii |hi )/ {print substr($0, 1, 2)}')
fi

if [ -n "${APT_REQD}" ] || [ "${DPKG_ERROR}" -ne 0 ]; then
echo -e "\n${cyanbold}Installing packages${normal}"
echo -e "$ sudo apt install -y ${PACKAGES}"
# shellcheck disable=SC2086
sudo apt install -y ${PACKAGES}
fi

# Note GBM may not do much in this set-up, but there are dri/drm name issues
# /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so must exist (from apt install above)
if [ -e "/usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so" ]; then

echo -e "\n${cyanbold}Symlinks to gbm/dri_gbm.so${normal}"
echo -e "> Note: Overwrites symlinks every time"
# Quietly ensure other folder exists (but should already be there)
sudo mkdir -p /usr/lib/x86_64-linux-gnu/dri

echo -e "$ sudo ln -s /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/gbm/drm_gbm.so"
sudo ln -sf /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/gbm/drm_gbm.so

echo -e "$ sudo ln -s /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/dri/dri_gbm.so"
sudo ln -sf /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/dri/dri_gbm.so

echo -e "$ sudo ln -s /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/dri/drm_gbm.so"
sudo ln -sf /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/dri/drm_gbm.so

fi

# Ensure system libraries are loaded.
# This stops the following environment variable from being needed:
# LD_LIBRARY_PATH=/usr/lib/wsl/lib:/usr/lib/x86_64-linux-gnu/dri

if [ ! -f "/etc/ld.so.conf.d/phil-wslg.conf" ] || \
[ ! -f "/etc/ld.so.conf.d/phil-dri-gbm.conf" ]; then

echo -e "\n${cyanbold}Configuring system library paths${normal}"
# Quietly ensure folder exists (but should already be there)
sudo mkdir -p /etc/ld.so.conf.d

if [ ! -f "/etc/ld.so.conf.d/phil-wslg.conf" ]; then
echo -e "$ echo '/usr/lib/wsl/lib' | sudo tee /etc/ld.so.conf.d/phil-wslg.conf"
echo '/usr/lib/wsl/lib' | sudo tee /etc/ld.so.conf.d/phil-wslg.conf > /dev/null
fi

if [ ! -f "/etc/ld.so.conf.d/phil-dri-gbm.conf" ]; then
echo -e "$ echo '/usr/lib/x86_64-linux-gnu/dri' | sudo tee /etc/ld.so.conf.d/\
phil-dri-gbm.conf"
echo '/usr/lib/x86_64-linux-gnu/dri' | sudo tee /etc/ld.so.conf.d/\
phil-dri-gbm.conf > /dev/null
fi

# Update the linker cache so the system sees the new libs immediately
echo -e "$ sudo ldconfig"
sudo ldconfig

fi

# Setting system-wide environment variables for WSLg

WSLG_VARS="\
# --- Driver / Hardware Layer ---
EGL_PLATFORM=wayland
WAYLAND_DEBUG=1
WSA_RENDER_DEVICE=/dev/dri/renderD128
GALLIUM_DRIVER=d3d12
MESA_D3D12_DEFAULT_ADAPTER_NAME=NVIDIA
MESA_VK_WSI_PRESENT_MODE=immediate

# --- Toolkit / Application Layer ---
# Qt (KDE, VLC, qBittorrent)
QT_QPA_PLATFORM=wayland
# KWin Direct Rendering Manager No Atomic Mode Setting
KWIN_DRM_NO_AMS=1
# Set KDE version for file paths
Environment=KDE_SESSION_VERSION=6
# GTK (GNOME, GIMP, LibreOffice)
GDK_BACKEND=wayland
# Mozilla (Firefox, Thunderbird)
MOZ_ENABLE_WAYLAND=1
# Electron (VS Code, Discord, Slack, Obsidian)
ELECTRON_OZONE_PLATFORM_HINT=wayland
ELECTRON_OZONE_PLATFORM=wayland
# SDL (Games)
SDL_VIDEODRIVER=wayland
# GLFW (Minecraft, Indie Games)
GLFW_PLATFORM=wayland
# Rust winit (Alacritty, WezTerm)
WINIT_UNIX_BACKEND=wayland

# --- Compatibility Fixes ---
# Fixes blank/gray windows in Java apps (IntelliJ, NetBeans) running on XWayland
_JAVA_AWT_WM_NONREPARENTING=1

# --- Session Identity ---
XDG_SESSION_TYPE=wayland
XDG_CURRENT_DESKTOP=KDE
KWIN_OPENGL_INTERFACE=egl
"

if ! cmp -s <(echo -e "${WSLG_VARS}") /etc/environment.d/\
01-graphics-on-wsl.conf; then

echo -e "\n${cyanbold}Setting system-wide environment variables for WSLg\
${normal}"
# Quietly ensure folder exists (but should already be there)
sudo mkdir -p /etc/environment.d

echo -e "$ echo -e \"\${WSLG_VARS}\" | sudo tee /etc/environment.d/\
01-graphics-on-wsl.conf 1> /dev/null"
echo -e "${WSLG_VARS}" | sudo tee /etc/environment.d/\
01-graphics-on-wsl.conf 1> /dev/null

echo -e "\n${cyanbold}Print current systemd user environment${normal}"
echo -e "$ systemctl --user show-environment\n"
systemctl --user show-environment

echo -e "\n${cyanbold}Add to current systemd user environment${normal}"
echo -e "> Needed for first launch of Weston & Plasma from this script"
echo -e "$ echo -e \"\${WSLG_VARS}\" | grep -v '^$' | grep -v '^#' | \
xargs systemctl --user set-environment"
echo -e "${WSLG_VARS}" | grep -v '^$' | grep -v '^#' | \
xargs systemctl --user set-environment

echo -e "\n${cyanbold}Print updated systemd user environment${normal}"
echo -e "$ systemctl --user show-environment\n"
systemctl --user show-environment

fi

echo -e "\n${cyanbold}Export variables to current shell for testing${normal}"
echo -e "> Needed for glxinfo & elginfo below in this script"
echo -e "$ export \$(echo \"\${WSLG_VARS}\" | grep -v '^$' | grep -v '^#' | \
xargs)"
export $(echo "${WSLG_VARS}" | grep -v '^$' | grep -v '^#' | xargs)

# Check WSL kernel version

echo -e "\n${cyanbold}Show WSL kernel version${normal}"
echo -e "$ wsl.exe --version\n"
wsl.exe --version
echo -e "\n$ uname -a\n"
uname -a
WSL_KERNEL=$(powershell.exe -NoProfile -Command "(wsl.exe --version) \
-replace '[^ -~]', ''" | grep -i "Kernel version" \
| sed 's/^Kernel version: //' | grep -oE "^[0-9.]+")
echo -e "\n> WSL_KERNEL=${WSL_KERNEL}"
DEB_KERNEL=$(uname -r | grep -oE "^[0-9.]+")
echo -e "\n> DEB_KERNEL=${DEB_KERNEL}"
if [ "${WSL_KERNEL}" == "${DEB_KERNEL}" ]; then
echo -e "${greenbold}> Kernel versions match${normal}"
else
echo -e "${redbold}> Kernel versions do NOT match${normal}\n"
fi

# Now can test mesa using d3d12 and nvidia graphics without passing variables

echo -e "\n${cyanbold}Show glxinfo${normal}"
echo -e "$ glxinfo -B\n"
glxinfo -B
echo -e "\n${cyanbold}Show eglinfo${normal}"
# Backslash to prevent the variable being set from expanding in echo command
echo -e "$ \$EGL_LOG_LEVEL=debug eglinfo -B"
echo -e "${redbold}
> Known issue: No GBM (apparently wslg/d3d12 converts EGL to Win-native
  calls instead)
> Known issue: No DRI3 for X11 (apparently wslg/d3d12 works around with
  DRI2+XWayland)
> Known issue: Surfaceless platform needs to use a software-based loader
  (buffer manager) but still appears to be hardware accelerated
> Known issue: No DRI config for 10-bit or 16-bit colour (in wslg/d3d12)
${normal}"
EGL_LOG_LEVEL=debug eglinfo -B

# Define systemd unit for Weston (Plow)

WESTON_SERVICE="\
[Unit]
Description=Weston compositor (nested on WSLg)
Documentation=man:weston(1)
After=graphical-session-pre.target
PartOf=graphical-session.target
# Automatically pull in the session
Wants=nested-plasma.service
# Ensure display starts before session
Before=nested-plasma.service

[Service]
Type=notify
ExecStart=/usr/bin/weston --socket=weston
Restart=no
ExecStopPost=/bin/rm -f %t/weston %t/weston.lock
"

# Define systemd unit for Plasma

PLASMA_SERVICE="\
[Unit]
Description=KDE Plasma session (nested on Weston)
After=plow.service
BindsTo=plow.service

[Service]
Type=notify
NotifyAccess=all
Environment=WAYLAND_DISPLAY=weston
Environment=XDG_SESSION_CLASS=user
Environment=XDG_SESSION_TYPE=wayland
Environment=XDG_SESSION_DESKTOP=KDE
Environment=XDG_CURRENT_DESKTOP=KDE
ExecStart=/bin/bash -c '/usr/bin/startplasma-wayland & PID=\$!; ( until qdbus org.kde.plasmashell > /dev/null 2>&1; do sleep 0.1; done; systemd-notify --ready ) & wait \$PID'
Restart=no

[Install]
WantedBy=plow.service
"

# Configure system-wide systemd user units

echo -e "\n${cyanbold}Configuring system-wide systemd units${normal}"

# Quietly ensure folder exists (but should already be there)
sudo mkdir -p /etc/systemd/user

# Configure plow.service systemd unit
if [ ! -f /etc/systemd/user/plow.service ] || \
! cmp -s <(echo -e "${WESTON_SERVICE}") /etc/systemd/user/plow.service; then
echo -e "\n${cyanbold}Configure plow.service systemd unit${normal}"
# Escape with backslashes to show variable name not contents in echo output
echo -e "$ echo -e \"\${WESTON_SERVICE}\" | sudo tee /etc/systemd/user/\
plow.service > /dev/null"
echo -e "${WESTON_SERVICE}" | sudo tee /etc/systemd/user/\
plow.service > /dev/null
UNITS_CHANGED=1
fi

# Configure nested-plasma.service systemd unit
if [ ! -f /etc/systemd/user/nested-plasma.service ] || \
! cmp -s <(echo -e "${PLASMA_SERVICE}") /etc/systemd/user/nested-plasma.service
then
echo -e "\n${cyanbold}Configure nested-plasma.service systemd unit${normal}"
# Escape with backslashes to show variable name not contents in echo output
echo -e "$ echo -e \"\${PLASMA_SERVICE}\" | sudo tee /etc/systemd/user/\
nested-plasma.service > /dev/null"
echo -e "${PLASMA_SERVICE}" | sudo tee /etc/systemd/user/\
nested-plasma.service > /dev/null
UNITS_CHANGED=1
fi

# Reload systemd if units changed
if [ "${UNITS_CHANGED}" -eq 1 ]; then
echo -e "\n${cyanbold}Reload systemd user daemon${normal}"
echo -e "$ systemctl --user daemon-reload"
systemctl --user daemon-reload
fi

# Show all systemd units in context (existing along with new plow & plasma)
echo -e "\n${cyanbold}Listing available user units${normal}"
echo -e "$ systemctl --user list-unit-files\n"
systemctl --user list-unit-files

# Run plow.service
echo -e "\n${cyanbold}Run plow.service${normal}"
echo -e "$ systemctl --user start plow.service"
systemctl --user start plow.service

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

