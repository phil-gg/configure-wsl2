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

# Create plasma-nm-dummy package
# (Don't need a GUI tool to manage network connections when running within WSL2)

DPKG_OUTPUT=$(dpkg -l plasma-nm-dummy 2> /dev/null)
DPKG_ERROR=$?
if [ "${DPKG_ERROR}" -eq 0 ]; then
START_LINE=$(echo "$DPKG_OUTPUT" | awk '/^\+\+\+-=/ {print NR + 1; exit}')
# shellcheck disable=SC2086
DPKG_TAIL=$(echo "${DPKG_OUTPUT}" | tail -n +${START_LINE})
DUMMY_REQD=$(echo "${DPKG_TAIL}" | awk '!/^(ii |hi )/ {print substr($0, 1, 2)}')
fi

if [ -n "${DUMMY_REQD}" ] || [ "${DPKG_ERROR}" -ne 0 ]; then
echo -e "\n${cyanbold}Installing plasma-nm-dummy package${normal}"

echo -e "$ mkdir -p ~/git/${github_username}/${github_project}/tmp"
mkdir -p "${HOME}/git/${github_username}/${github_project}/tmp"

echo -e "$ cd ~/git/${github_username}/${github_project}/tmp"
cd "${HOME}/git/${github_username}/${github_project}/tmp" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 103; }

PLASMA_NM_DUMMY="\
Section: misc
Priority: optional
Standards-Version: 3.9.2

Package: plasma-nm-dummy
Provides: plasma-nm
Conflicts: plasma-nm
Architecture: all
Description: Dependency resolving dummy pkg for deliberately missing plasma-nm
"
# Show variable without expansion here (with backslash escapes)
echo -e "$ echo -e \"\${PLASMA_NM_DUMMY}\" | sudo tee plasma-nm-dummy > \
/dev/null 2>&1"
echo -e "${PLASMA_NM_DUMMY}" | sudo tee plasma-nm-dummy > /dev/null 2>&1
echo -e "$ cat plasma-nm-dummy\n"
cat plasma-nm-dummy

echo -e "\n$ equivs-build plasma-nm-dummy\n"
equivs-build plasma-nm-dummy

echo -e "\n$ sudo dpkg -i plasma-nm-dummy_1.0_all.deb\n"
sudo dpkg -i plasma-nm-dummy_1.0_all.deb

echo -e "$ cd ~/git/${github_username}/${github_project}"
cd "${HOME}/git/${github_username}/${github_project}" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 104; }

echo -e "$ rm -rf ~/git/${github_username}/${github_project}/tmp"
rm -rf "${HOME}/git/${github_username}/${github_project}/tmp"

fi

# Update apt if last `sudo apt update` more than one hour ago

last_update=$(stat -c %Y /var/cache/apt/pkgcache.bin 2>/dev/null || echo 0)
if (( now - last_update > 3600 )); then
echo -e "\n${cyanbold}Update apt then check for required packages${normal}"
echo -e "$ sudo apt update"
sudo apt update
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
kwin-wayland \
wl-clipboard"

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
# Only uncomment when you want (lots!) more wayland logging
# WAYLAND_DEBUG=1
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
KDE_SESSION_VERSION=6
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
echo -e "$ systemctl --user show-environment --no-pager\n"
systemctl --user show-environment --no-pager

echo -e "\n${cyanbold}Add to current systemd user environment${normal}"
echo -e "> Needed for first launch of Weston & Plasma from this script"
echo -e "$ echo -e \"\${WSLG_VARS}\" | grep -v '^$' | grep -v '^#' | \
xargs systemctl --user set-environment"
echo -e "${WSLG_VARS}" | grep -v '^$' | grep -v '^#' | \
xargs systemctl --user set-environment

# Add environment variables to D-Bus, too
echo -e "\n$ dbus-update-activation-environment --systemd --all"
dbus-update-activation-environment --systemd --all

echo -e "\n${cyanbold}Print updated systemd user environment${normal}"
echo -e "$ systemctl --user show-environment --no-pager\n"
systemctl --user show-environment --no-pager

fi

echo -e "\n${cyanbold}Export variables to current shell for testing${normal}"
echo -e "> Needed for glxinfo & elginfo below in this script"
echo -e "$ export \$(echo \"\${WSLG_VARS}\" | grep -v '^$' | grep -v '^#' | \
xargs)"
export $(echo "${WSLG_VARS}" | grep -v '^$' | grep -v '^#' | xargs)

# Check WSL kernel version

echo -e "\n${cyanbold}Show WSL kernel version${normal}"
echo -e "$ wsl.exe --version < /dev/null | tr -cd '\\\\040-\\\\176\\\\012'\n"
WSL_VERSION=$(wsl.exe --version < /dev/null | tr -cd '\040-\176\012')
echo "${WSL_VERSION}"

echo -e "\n$ uname -a\n"
uname -a

WSL_KERNEL=$(echo "${WSL_VERSION}" | grep -i "Kernel version" | \
sed 's/^Kernel version: //' | grep -oE "^[0-9.]+")
echo -e "\n> WSL_KERNEL=${WSL_KERNEL}"
DEB_KERNEL=$(uname -r | grep -oE "^[0-9.]+")
echo -e "> DEB_KERNEL=${DEB_KERNEL}"

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
echo -e "${redbold}> Known issue: GBM\EGL (but apparently wslg/d3d12 works \
around this)${normal}\n"
EGL_LOG_LEVEL=debug eglinfo -p gbm
eglinfo -B -p wayland
eglinfo -B -p x11
eglinfo -B -p surfaceless

# Define systemd unit for Weston (Plow)

WESTON_SERVICE="\
# plow-weston.service
# Just a virtual display
# A customised /usr/lib/systemd/user/plasma-kwin_wayland.service depends on this

[Unit]
Description=Weston compositor (nested on WSLg)
# https://manpages.debian.org/trixie/weston/weston.1.en.html
Documentation=man:weston(1)
After=graphical-session-pre.target
# Not sure I want Plow to be part of graphical-session
# PartOf=graphical-session.target
# Looks like the stopping is too agressive for this use-case
# StopWhenUnneeded=true

[Service]
Type=notify
ExecStart=/usr/bin/weston --socket=weston
Restart=no
ExecStopPost=/bin/rm -f %t/weston %t/weston.lock
"

# Define the config change for Plasma

PLASMA_CONF="\
# plow-plasma.conf
# Injects plow-weston dependencies into KWin
# Customises /usr/lib/systemd/user/plasma-kwin_wayland.service

[Unit]
After=plow-weston.service
# Without plow-weston, customised plasma-kwin_wayland cannot run
Requires=plow-weston.service
# When plow-weston stops/dies, apply to kwin too (stronger than Wants)
BindsTo=plow-weston.service
# When plow-weston is restarted, apply to customised plasma-kwin_wayland too
PartOf=plow-weston.service
# When plow-weston is reloaded, apply to customised plasma-kwin_wayland too
ReloadPropagatedFrom=plow-weston.service

[Service]
# Ensure these variables are set as part of plasma-kwin_wayland customisations
Environment=WAYLAND_DISPLAY=weston
Environment=XDG_SESSION_CLASS=user
Environment=XDG_SESSION_TYPE=wayland
Environment=XDG_SESSION_DESKTOP=KDE
Environment=XDG_CURRENT_DESKTOP=KDE
"

CLIPPY="\
# plow-clippy.service
# Bridge to put each copy within Plow onto Windows host clipboard

[Unit]
Description=Clipboard Bridge (Plow to Windows)
# For startup, wait for the whole Plasma workspace to fully initialise
After=plasma-workspace.target
# For teardown, stop plow-clippy with the rest of Plasma workspace
PartOf=plasma-workspace.target
# Without plasma-kwin_wayland, plow-clippy cannot run
Requires=plasma-kwin_wayland.service
# When kwin stops/dies, apply to plow-clippy too (stronger than Wants)
BindsTo=plasma-kwin_wayland.service
# When plasma-kwin_wayland is reloaded, apply to plow-clippy too
ReloadPropagatedFrom=plasma-kwin_wayland.service

[Service]
Type=simple
# Pipe the Wayland clipboard into the Windows clip.exe utility
ExecStart=/bin/bash -c '/usr/bin/wl-paste -t text/plain --watch /mnt/c/Windows/System32/clip.exe'
Restart=on-failure
RestartSec=2

[Install]
# Startup with the rest of Plasma workspace
WantedBy=plasma-workspace.target
"

# TO-DO: Further clipboard integration work

# Configure system-wide systemd user units

echo -e "${bluebold}Define systemd & dbus services for Plow${normal}"

# Set file locations once as variables

WESTON_UNIT_DIR="/etc/systemd/user"
WESTON_UNIT_FILE="${WESTON_UNIT_DIR}/plow-weston.service"
PLASMA_CONF_DIR="/etc/systemd/user/plasma-kwin_wayland.service.d"
PLASMA_CONF_FILE="${PLASMA_CONF_DIR}/plow-plasma.conf"

# Quietly ensure folders exist
sudo mkdir -p "${PLASMA_CONF_DIR}"

# Configure plow-weston.service systemd unit
if [ ! -f "${WESTON_UNIT_FILE}" ] || \
! cmp -s <(echo -e "${WESTON_SERVICE}") "${WESTON_UNIT_FILE}"; then
echo -e "\n${cyanbold}Configure plow-weston.service systemd unit${normal}"
# Choosing to expand path but not file contents in echo output here
# Hence backslash escapes for WESTON_SERVICE variable
echo -e "$ echo -e \"\${WESTON_SERVICE}\" | sudo tee ${WESTON_UNIT_FILE} > \
/dev/null"
echo -e "${WESTON_SERVICE}" | sudo tee "${WESTON_UNIT_FILE}" > /dev/null
UNITS_CHANGED=1
fi

# Configure plasmashell customisation
if [ ! -f "${PLASMA_CONF_FILE}" ] || \
! cmp -s <(echo -e "${PLASMA_CONF}") "${PLASMA_CONF_FILE}"; then
echo -e "\n${cyanbold}Customise plasmashell systemd unit${normal}"
# Choosing to expand path but not file contents in echo output here
# Hence backslash escapes for PLASMA_CONF variable
echo -e "$ echo -e \"\${PLASMA_CONF}\" | sudo tee ${PLASMA_CONF_FILE} > \
/dev/null"
echo -e "${PLASMA_CONF}" | sudo tee "${PLASMA_CONF_FILE}" > /dev/null
UNITS_CHANGED=1
fi

# Reload systemd if units changed
if [ "${UNITS_CHANGED}" -eq 1 ]; then
echo -e "\n${cyanbold}Reload systemd user daemon${normal}"
echo -e "$ systemctl --user daemon-reload"
systemctl --user daemon-reload
fi

# Show all systemd units in context (existing along with new plow & plasma)
echo -e "\n${cyanbold}Listing all available systemd user unit-files${normal}"
echo -e "$ systemctl --user list-unit-files --no-pager\n"
systemctl --user list-unit-files --no-pager

# Run plow-plasma.service
echo -e "\n${cyanbold}Run Plow session${normal}"
echo -e "$ startplasma-wayland &"
startplasma-wayland &

# TO-DO: Still need a clean shutdown command - this one does NOT work!

# Stop a Plow session
echo -e "\n${bluebold}Stop a Plow session with:${normal}"
echo -e "${cyanbold}dbus-send --session --dest=org.kde.ksmserver \
--type=method_call /KSMServer org.kde.KSMServerInterface.logout \
int32:0 int32:0 int32:0${normal}"
# The three zeros are:
# Confirm (0): Do not show the graphical logout confirmation dialogue
# Type (0): Perform a standard logout (rather than a reboot or shutdown)
# Mode (0): Schedule the logout, allowing applications to save state gracefully
echo -e "> This triggers a clean logout & safely stops the nested compositor."

# Error logs for Plow
echo -e "\n${bluebold}View error logs for Plow with:${normal}"
echo -e "${cyanbold}systemctl --user status plow-weston plasma-kwin_wayland \
plasma-workspace.target --no-pager${normal}"
echo -e "${cyanbold}journalctl --user -x -b -u plow-weston.service \
--no-pager${normal}"
echo -e "${cyanbold}journalctl --user -x -b -u plasma-kwin_wayland.service \
--no-pager${normal}"

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

