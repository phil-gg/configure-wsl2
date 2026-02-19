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
KDE_CONF_CHANGED=0
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

WESTON_FOLDER="/etc/xdg/weston"
WESTONCONF_FILENAME="weston.ini"
WESTON_FILEPATH="${WESTON_FOLDER}/${WESTONCONF_FILENAME}"

WESTON_CONFIG="\
[core]
# https://manpages.debian.org/trixie/weston/weston.ini.5.en.html
# Enables support for X11 applications
# xwayland=true
# Force wayland backend
backend=wayland
# Use the Kiosk shell to force the nested app to fill the screen
shell=kiosk-shell.so
# Load the systemd notification module
modules=systemd-notify.so
# Set output repaint window to 8 ms maximum, which should support up to 125 Hz display refresh rates
repaint-window=8
# Disable screen blanking
idle-time=0
# Force graphics acceleration
renderer=gl

[libinput]
# Enables tap to click on touchpad devices
enable-tap=true
# Enables tap and drag on touchpad devices
tap-and-drag=true
# Disable other devices while typing on keyboard
disable-while-typing=false
# Disable clicking both left and right buttons together simulating middle click
middle-button-emulation=false
# Enable touchscreen calibrator interface
touchscreen_calibrator=false

[shell]
# Set background color to opaque black
background-color=0xff000000
# Enables screen locking (Boolean)
locking=false
# Opening new windows animation
animation=none
# Closing windows animation
close-animation=none
# Effect used by desktop-shell when starting up
startup-animation=none
# Effect used with focused vs unfocused windows
focus-animation=dim-layer
# Weston quits when the Ctrl-Alt-Backspace key combination is pressed
allow-zap=true
# Modifier key for bindings - see https://manpages.debian.org/trixie/weston/weston-bindings.7.en.html
binding-modifier=alt
# Set the cursor theme
# cursor-theme=
# Set the cursor size
cursor-size=48

[keyboard]
keymap_model=pc105
keymap_layout=gb
keymap_variant=extd
"

if [ ! -f "${WESTON_FILEPATH}" ] || \
! cmp -s <(echo -e "${WESTON_CONFIG}") "${WESTON_FILEPATH}"; then
echo -e "\n${cyanbold}Configure weston${normal}"
echo -e "$ sudo mkdir -p ${WESTON_FOLDER}"
sudo mkdir -p "${WESTON_FOLDER}"
echo -e "$ echo -e \"\${WESTON_CONFIG}\" | sudo tee ${WESTON_FILEPATH} > /dev/null"
echo -e "${WESTON_CONFIG}" | sudo tee "${WESTON_FILEPATH}" > /dev/null
echo -e "$ ln -sf ${WESTON_FILEPATH} ~/.config/weston.ini"
ln -sf "${WESTON_FILEPATH}" "${HOME}/.config/weston.ini"
fi

# Ensure /tmp/.X11-unix is a local, writable directory with a sticky bit
# This allows a nested Xwayland (inside Plow) to create its own sockets

TMPCONF_FILE="/etc/tmpfiles.d/plow-xwayland.conf"
TMPCONF_TEXT="\
# See tmpfiles.d(5) for details
# Type Path           Mode UID  GID  Age Argument
d      /tmp/.X11-unix 1777 root root -   -
"

if [ ! -f "${TMPCONF_FILE}" ] || \
! cmp -s <(printf "%s" "${TMPCONF_TEXT}") "${TMPCONF_FILE}"; then

echo -e "\n${cyanbold}Configuring Xwayland for Plow${normal}"
sudo mkdir -p /etc/tmpfiles.d
echo -e "$ printf \"%s\" \"\${TMPCONF_TEXT}\" | sudo tee ${TMPCONF_FILE} > \
/dev/null"
printf "%s" "${TMPCONF_TEXT}" | sudo tee "${TMPCONF_FILE}" > /dev/null

# Apply the fix immediately to the current session
if [ ! -d "/tmp/.X11-unix" ]; then
echo -e "$ sudo systemd-tmpfiles --create ${TMPCONF_FILE}"
sudo systemd-tmpfiles --create "${TMPCONF_FILE}"
fi

fi

# Apply KDE plasma taskbar customisations once, on first session launch

DIR_SKEL="/etc/skel/.local/share/plasma/shells/org.kde.plasma.desktop/contents"
DIR_HOME="${HOME}/.local/share/plasma/shells/org.kde.plasma.desktop/contents"

S_FILE_SKEL="${DIR_SKEL}/kde-plasma.svg"

SVG_TEXT="\
<svg viewBox=\"0 0 44 44\" xmlns=\"http://www.w3.org/2000/svg\">
  <defs>
    <linearGradient
      id=\"a\"
      gradientUnits=\"userSpaceOnUse\"
      x1=\"3\"
      y1=\"3\"
      x2=\"41\"
      y2=\"41\">
      <stop
        offset=\"0\"
        stop-color=\"#2bc0ff\" />
      <stop
        offset=\"1\"
        stop-color=\"#1d99f3\" />
    </linearGradient>
  </defs>
  <rect fill=\"url(#a)\"
    width=\"40\"
    height=\"40\"
    x=\"2\"
    y=\"2\"
    rx=\"5\"
    ry=\"5\" />
  <path fill=\"#fff\"
    d=\"m14 6c-1.108 0-2 0.892-2 2c0 1.108 0.892 2 2 2c1.108 0 2-0.892 2-2c0
       -1.108-0.892-2-2-2zm14 0l-4 4l6 6l-6 6l4 4l6-6l4-4zm-19 12c-1.662 0-3
       1.338-3 3c0 1.662 1.338 3 3 3c1.662 0 3-1.338 3-3c0-1.662-1.338-3-3-3zm9
       12c-2.216 0-4 1.784-4 4c0 2.216 1.784 4 4 4c2.216 0 4-1.784 4-4c0-2.216
       -1.784-4-4-4z\" />
</svg>
"

L_FILE_SKEL="${DIR_SKEL}/layout.js"
L_FILE_HOME="${DIR_HOME}/layout.js"

LAYOUT_JS_TEXT="\
var taskbar = new Panel(\"org.kde.plasma.panel\")
taskbar.height = 44
taskbar.location = \"bottom\"
taskbar.floating = 0

// Kickoff (Start Menu) with custom SVG icon
var kickoff = taskbar.addWidget(\"org.kde.plasma.kickoff\")
kickoff.currentConfigGroup = [\"General\"]
kickoff.writeConfig(\"icon\", \"${S_FILE_SKEL}\")

// Standard Task Manager (Icons + Text, no pinned apps)
var tasks = taskbar.addWidget(\"org.kde.plasma.taskmanager\")
tasks.currentConfigGroup = [\"General\"]
tasks.writeConfig(\"launchers\", \"\")

// Spacer (Expanding pushes subsequent widgets to the right)
var spacer = taskbar.addWidget(\"org.kde.plasma.panelspacer\")

// System Tray (Right-aligned via the spacer)
var systray = taskbar.addWidget(\"org.kde.plasma.systemtray\")

// Digital Clock (Far right edge)
var digitalclock = taskbar.addWidget(\"org.kde.plasma.digitalclock\")
"

if [ ! -f "${L_FILE_SKEL}" ] || \
     ! cmp -s <(printf "%s" "${LAYOUT_JS_TEXT}") "${L_FILE_SKEL}" || \
   [ ! -e "${L_FILE_HOME}" ] || \
     ! cmp -s <(printf "%s" "${LAYOUT_JS_TEXT}") "${L_FILE_HOME}" || \
   [ ! -f "${S_FILE_SKEL}" ] || \
     ! cmp -s <(printf "%s" "${SVG_TEXT}") "${S_FILE_SKEL}"; then

echo -e "\n${cyanbold}Set custom KDE plasma 6 layout${normal}"

# Force regeneration by removing existing config
echo -e "$ rm -f ~/.config/plasma-org.kde.plasma.desktop-appletsrc"
rm -f "${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"

sudo mkdir -p "${DIR_SKEL}"
mkdir -p "${DIR_HOME}"

echo -e "$ printf \"%s\" \"\${SVG_TEXT}\" | sudo tee ${S_FILE_SKEL} > \
/dev/null"
printf "%s" "${SVG_TEXT}" | sudo tee "${S_FILE_SKEL}" > /dev/null

echo -e "$ printf \"%s\" \"\${LAYOUT_JS_TEXT}\" | sudo tee ${L_FILE_SKEL} > \
/dev/null"
printf "%s" "${LAYOUT_JS_TEXT}" | sudo tee "${L_FILE_SKEL}" > /dev/null

echo -e "$ ln -sf ${L_FILE_SKEL} ${L_FILE_HOME}"
ln -sf "${L_FILE_SKEL}" "${L_FILE_HOME}"

fi

# Define function to build and install a dummy package

create_dummy_pkg() {
local TARGET_PKG="$1"
local DUMMY_PKG="${TARGET_PKG}-dummy"
local TMP_DIR="${HOME}/git/${github_username}/${github_project}/tmp"

DPKG_OUTPUT=$(dpkg -l "${DUMMY_PKG}" 2> /dev/null)
DPKG_ERROR=$?
DUMMY_REQD=""

if [ "${DPKG_ERROR}" -eq 0 ]; then
START_LINE=$(echo "$DPKG_OUTPUT" | awk '/^\+\+\+-=/ {print NR + 1; exit}')
# shellcheck disable=SC2086
DPKG_TAIL=$(echo "${DPKG_OUTPUT}" | tail -n +${START_LINE})
DUMMY_REQD=$(echo "${DPKG_TAIL}" | awk '!/^(ii |hi )/ {print substr($0, 1, 2)}')
fi

if [ -n "${DUMMY_REQD}" ] || [ "${DPKG_ERROR}" -ne 0 ]; then
echo -e "\n${cyanbold}Installing ${DUMMY_PKG} package${normal}"

echo -e "$ mkdir -p ${TMP_DIR}"
mkdir -p "${TMP_DIR}"

echo -e "$ cd ${TMP_DIR}"
cd "${TMP_DIR}" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 103; }

DUMMY_PAYLOAD="\
Section: misc
Priority: optional
Standards-Version: 3.9.2

Package: ${DUMMY_PKG}
Version: 1.0
Provides: ${TARGET_PKG}
Conflicts: ${TARGET_PKG}
Architecture: all
Description: Dependency resolving dummy pkg for deliberately missing ${TARGET_PKG}
"
# Show payload variable without expansion here (with backslash escapes)
echo -e "$ echo -e \"\${DUMMY_PAYLOAD}\" | sudo tee ${DUMMY_PKG} > /dev/null 2>&1"
echo -e "${DUMMY_PAYLOAD}" | sudo tee "${DUMMY_PKG}" > /dev/null 2>&1
echo -e "$ cat ${DUMMY_PKG}\n"
cat "${DUMMY_PKG}"

echo -e "\n$ equivs-build ${DUMMY_PKG}\n"
equivs-build "${DUMMY_PKG}"

echo -e "\n$ sudo dpkg -i ${DUMMY_PKG}_1.0_all.deb\n"
sudo dpkg -i "${DUMMY_PKG}_1.0_all.deb"

echo -e "$ cd ~/git/${github_username}/${github_project}"
cd "${HOME}/git/${github_username}/${github_project}" 2> /dev/null \
|| { echo -e "  ${redbold}Failed to change directory, exiting${normal}"\
; exit 104; }

echo -e "$ rm -rf ${TMP_DIR}"
rm -rf "${TMP_DIR}"

fi
}

# Create dummy packages
# (Don't need GUI tools for network, power, or bluetooth in WSL2)

create_dummy_pkg "plasma-nm"
create_dummy_pkg "powerdevil"
create_dummy_pkg "bluedevil"

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
x11-apps \
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

if [ ! -L "/usr/lib/x86_64-linux-gnu/gbm/drm_gbm.so" ] || \
[ ! -L "/usr/lib/x86_64-linux-gnu/dri/dri_gbm.so" ] || \
[ ! -L "/usr/lib/x86_64-linux-gnu/dri/drm_gbm.so" ]; then

echo -e "\n${cyanbold}Create symlinks to gbm/dri_gbm.so${normal}"
# Quietly ensure other folder exists (but should already be there)
sudo mkdir -p /usr/lib/x86_64-linux-gnu/dri

if [ ! -L "/usr/lib/x86_64-linux-gnu/gbm/drm_gbm.so" ]; then
echo -e "$ sudo ln -s /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/gbm/drm_gbm.so"
sudo ln -sf /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/gbm/drm_gbm.so
fi

if [ ! -L "/usr/lib/x86_64-linux-gnu/dri/dri_gbm.so" ]; then
echo -e "$ sudo ln -s /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/dri/dri_gbm.so"
sudo ln -sf /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/dri/dri_gbm.so
fi

if [ ! -L "/usr/lib/x86_64-linux-gnu/dri/drm_gbm.so" ]; then
echo -e "$ sudo ln -s /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/dri/drm_gbm.so"
sudo ln -sf /usr/lib/x86_64-linux-gnu/gbm/dri_gbm.so \
/usr/lib/x86_64-linux-gnu/dri/drm_gbm.so
fi

fi

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

# --- Session Identity ---
XDG_SESSION_TYPE=wayland
XDG_SESSION_DESKTOP=KDE
XDG_CURRENT_DESKTOP=KDE
XDG_MENU_PREFIX=plasma-
KWIN_OPENGL_INTERFACE=egl

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

# KDE Plasma config:
#  - Disable screen lock & sleep / shutdown /restart functionality
#  - Retain just logout

kscreenlockerrc="\
[Daemon][\$i]
Autolock=false
LockOnResume=false
Timeout=0
"

kdeglobals="\
[KDE Action Restrictions]
# https://develop.kde.org/docs/administration/kiosk/keys/
# The above webpage is right - 3x 'action/' prefix are required
action/lock_screen[\$i]=false
action/switch_user[\$i]=false
action/start_new_session[\$i]=false
logout[\$i]=true
"

ksmserverrc="\
[General]
# Do require logout confirmation and check for unsaved work
confirmLogout=true
# On login, start with an empty session (no reopening apps from last logout)
loginMode=emptySession
"

if [ ! -f /etc/xdg/kscreenlockerrc ] || \
! cmp -s <(echo -e "${kscreenlockerrc}") /etc/xdg/kscreenlockerrc; then
echo -e "\n${cyanbold}Configure kscreenlockerrc${normal}"
echo -e "$ echo -e \"\${kscreenlockerrc}\" | sudo tee /etc/xdg/kscreenlockerrc \
1> /dev/null"
echo -e "${kscreenlockerrc}" | sudo tee /etc/xdg/kscreenlockerrc 1> /dev/null
KDE_CONF_CHANGED=1
fi

if [ ! -f /etc/xdg/kdeglobals ] || \
! cmp -s <(echo -e "${kdeglobals}") /etc/xdg/kdeglobals; then
echo -e "\n${cyanbold}Configure kdeglobals${normal}"
echo -e "$ echo -e \"\${kdeglobals}\" | sudo tee /etc/xdg/kdeglobals \
1> /dev/null"
echo -e "${kdeglobals}" | sudo tee /etc/xdg/kdeglobals 1> /dev/null
KDE_CONF_CHANGED=1
fi

if [ ! -f /etc/xdg/ksmserverrc ] || \
! cmp -s <(echo -e "${ksmserverrc}") /etc/xdg/ksmserverrc; then
echo -e "\n${cyanbold}Configure ksmserverrc${normal}"
echo -e "$ echo -e \"\${ksmserverrc}\" | sudo tee /etc/xdg/ksmserverrc \
1> /dev/null"
echo -e "${ksmserverrc}" | sudo tee /etc/xdg/ksmserverrc 1> /dev/null
KDE_CONF_CHANGED=1
fi

# Reload systemd if units changed
if [ "${KDE_CONF_CHANGED}" -eq 1 ]; then
echo -e "\n${cyanbold}Reload cache for start menu layout${normal}"
echo -e "$ kbuildsycoca6 --noincremental"
kbuildsycoca6 --noincremental
fi

# run the mask command every time; it's a quick no-op if services already masked
echo -e "\n${cyanbold}Disable sleep shutdown restart${normal}"
echo -e "$ sudo systemctl mask \
sleep.target \
suspend.target \
hibernate.target \
hybrid-sleep.target \
poweroff.target \
reboot.target"
sudo systemctl mask \
sleep.target \
suspend.target \
hibernate.target \
hybrid-sleep.target \
poweroff.target \
reboot.target

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
echo -e "$ EGL_LOG_LEVEL=debug eglinfo -B"
echo -e "${redbold}> Known issue: GBM\\\\EGL (but apparently wslg/d3d12 works \
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
# For teardown, stop plow-weston with plasma-kwin_wayland.service
PartOf=plasma-kwin_wayland.service
# Could not get the below to stop Weston appropriately (commented out)
# Instead using the specific PartOf config above for desired stop behaviour
# StopWhenUnneeded=true

[Service]
Type=notify
# This is the command to start the service
# %t resolves to /run/user/\$(id -u)
ExecStart=/usr/bin/weston --socket=weston --width=1280 --height=960
# Activating and not activated until the following helper completes
ExecStartPost=/bin/bash -c 'while [ ! -S %t/weston ]; do sleep 0.1; done'
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

# Add services to share clipboards between host & guest

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
echo -e "$ if ! systemctl --user is-active plasma-workspace.target 1> \
/dev/null; then startplasma-wayland & disown; fi"
if ! systemctl --user is-active plasma-workspace.target 1> /dev/null; \
then startplasma-wayland & disown; fi

# Stop a Plow session
echo -e "\n${bluebold}Stop a Plow session with:${normal}"
echo -e "${cyanbold}qdbus6 org.kde.LogoutPrompt /LogoutPrompt \
org.kde.LogoutPrompt.promptLogout${normal}"

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

