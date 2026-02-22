#!/bin/bash

################################################################################
# Configure a {wslg > weston > kde-plasma} nested desktop environment, in an
# idempotent manner.
# See `#term-Idempotency` definition at:
# https://docs.ansible.com/ansible/latest/reference_appendices/glossary.html
# I'm calling this nested monstrosity 'plow', short for Plasma on WSLg.
#
# Copyright 2025-26 Philip Antrobus.
# Execution or reuse of this script, in part or in whole, indicates you accept
# that this work is made available strictly and only under the MIT-0 licence.
# SPDX-License-Identifier: MIT-0
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
USR_UNITS_CHANGED=0
SYS_UNITS_CHANGED=0

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
! cmp -s <(printf "%s" "${WESTON_CONFIG}") "${WESTON_FILEPATH}"; then
echo -e "\n${cyanbold}Configure weston${normal}"
echo -e "$ sudo mkdir -p ${WESTON_FOLDER}"
sudo mkdir -p "${WESTON_FOLDER}"
echo -e "$ printf \"%s\" \"\${WESTON_CONFIG}\" | sudo tee ${WESTON_FILEPATH} > \
/dev/null"
printf "%s" "${WESTON_CONFIG}" | sudo tee "${WESTON_FILEPATH}" > /dev/null
echo -e "$ ln -sf ${WESTON_FILEPATH} ~/.config/weston.ini"
ln -sf "${WESTON_FILEPATH}" "${HOME}/.config/weston.ini"
fi

# Apply KDE taskbar customisations using plasma6 updates directory

FACE_FILE="${HOME}/.face.icon"
FACE_TEXT="\
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"-2 -1 36 36\">
<defs>
<linearGradient id=\"a\" gradientUnits=\"userSpaceOnUse\" x1=\"-1\" y1=\"0\"
  x2=\"33\" y2=\"34\">
<stop offset=\"0\" stop-color=\"#2bc0ff\"/>
<stop offset=\"1\" stop-color=\"#1d99f3\"/>
</linearGradient>
</defs>
<rect fill=\"url(#a)\" width=\"36\" height=\"36\" x=\"-2\" y=\"-1\" rx=\"4\"
      ry=\"4\"/>
<path d=\"M27.83 25.07c-.16.18-.58.55-.83.79-.48.46-.7.66-1.29 1.13-1.16.94-1.15
         1.19-1.71 1.85-.38.44-.56.63-.75.75-.19.12-.45.26-.59.3-.69.21-1.44.03
         -1.97-.46a1.38 1.38 0 0 1-.36-.44l-.1-.16c-.2.14-.43.22-.65.33l-.41.19c
         -.19.08-.38.13-.57.2l-.45.15c-.21.06-.43.1-.64.14l-.41.07a8.51 8.51 0 0
         1-3.25-.21 7.29 7.29 0 0 1-.66-.2c-.3.24-.75.42-1.02.47-.27.05-.42.04
         -.65 0s-.4-.07-1.15-.39c-.75-.32-1.98-.68-2.87-.86s-1.31-.33-1.78-.48
         -.49-.17-.74-.23-.57-.2-.7-.3-.1-.1-.14-.15c-.08.18-.12.32-.13.44-.05
         .27.06.55.27.72.21.15.45.25.7.3.25.07.5.14.74.23.7.22.98.3 1.78.48 1.59
         .36 2 .48 2.87.85.58.26.85.35 1.15.4.17.03.49.03.65 0a2.2 2.2 0 0 0
         1.02-.47 8.28 8.28 0 0 0 7.04-.65l.09.15a2.07 2.07 0 0 0 2.35.9c.14-.04
         .41-.18.54-.27v.01c.23-.17.42-.35.8-.8.56-.65.55-.91 1.71-1.85.6-.47.8
         -.66 1.28-1.12a28 28 0 0 1 .52-.49c.3-.27.38-.35.46-.52.17-.35-.01-.65
         -.15-.8z\" opacity=\".2\"/>
<path d=\"M16 2c-2.68 0-5 2.5-5 5.6 0 7-4 7.7-4 12.6 0 5.41 4.03
         9.8 9 9.8s9-4.39 9-9.8c0-4.9-4-5.6-4-12.6C21 4.5 18.68 2 16 2z\"
      fill=\"#4f4f4f\"/>
<path d=\"M16 11c-1.79 0-3 1.52-3 3.4 0 4.25-3 4.67-3 7.65A5.98 5.98 0 0 0 16 28
         c3.31 0 6-2.66 6-5.95 0-2.98-3-3.4-3-7.65 0-1.88-1.21-3.4-3-3.4z\"
      opacity=\".1\"/>
<path d=\"M16 10c-1.79 0-3 1.52-3 3.4 0 4.25-3 4.67-3 7.65A5.98 5.98 0 0 0 16 27
         c3.31 0 6-2.66 6-5.95 0-2.98-3-3.4-3-7.65 0-1.88-1.21-3.4-3-3.4z\"
      fill=\"#fff\"/>
<path d=\"M11.52 29.98c-.3-.05-.57-.14-1.15-.39a12.9 12.9 0 0 0-2.87-.86c-.8-.18
         -1.09-.26-1.78-.48a9.43 9.43 0 0 0-.74-.23 1.89 1.89 0 0 1-.7-.3.76.76
         0 0 1-.27-.72c.02-.18.09-.36.27-.73.23-.5.83-.68.86-1.17.03-.3 0-.62
         -.07-1.3-.04-.4-.05-.54-.05-.8 0-.28 0-.08.03-.19.1-.4.19-.62.57-.72.1
         -.03-.12-.04.4-.05.31 0 .5-.01.54-.02.22-.06.38-.14.54-.28.14-.14.24
         -.88.42-1.21.3-.52.87-.51 1.34-.53.13.03.18.05.32.13a1 1 0 0 1 .32.26c
         .32.34.47.55 1.2 1.64.57.86.74 1.14.97 1.55.25.44.7 1.15.87 1.36l.39.5
         .37.48c.35.48.59 1.04.68 1.59.03.2.03.22.01.45a1.53 1.53 0 0 1-.13.6
         2.2 2.2 0 0 1-1.69 1.42c-.16.03-.48.03-.65 0z\" fill=\"#eab108\"/>
<path d=\"M23.21 29.65c.23-.17.42-.35.8-.79.56-.66.55-.92 1.71-1.86.59-.47.8-.66
         1.28-1.12a28 28 0 0 1 .52-.49c.3-.27.38-.35.46-.52a.67.67 0 0 0-.07-.7
         2.7 2.7 0 0 0-.53-.48c-.4-.3-.52-.57-.76-.95-.14-.23.04-.8-.18-1.38a
         5.76 5.76 0 0 0-.49-1 .87.87 0 0 0-.89-.3c-.1.02-.16.04-.6.24a8.2 8.2 0
         0 1-.54.24.99.99 0 0 1-.56 0c-.18-.06-.32.3-.6.11-.2-.13-.43-.3-.58-.33
         -.21-.06-.21-.06-.41-.04a.92.92 0 0 0-.5.2.8.8 0 0 0-.2.24.96.96 0 0 0
         -.17.33c-.12.4-.16.64-.3 1.82-.12.93-.15 1.23-.17 1.65a14.66 14.66 0 0
         1-.38 2.56c-.09.53-.06 1.08.1 1.56.05.17.07.2.17.37a1.38 1.38 0 0 0 .36
         .44c.53.49 1.3.67 1.99.46.14-.04.41-.18.54-.27z\" fill=\"#eab108\"/>
<circle cx=\"14\" cy=\"8\" r=\"2\" opacity=\".1\"/>
<circle cx=\"14\" cy=\"7\" r=\"2\" fill=\"#fff\"/>
<circle cx=\"14\" cy=\"7\" r=\"1\" fill=\"#323232\"/>
<path d=\"M19 10.5c0 1.93-1.34 3.5-3 3.5s-3-1.57-3-3.5z\" opacity=\".1\"/>
<path fill=\"#f77d00\" d=\"M19 9.5c0 1.93-1.34 3.5-3 3.5s-3-1.57-3-3.5z\"/>
<circle cx=\"18\" cy=\"8\" r=\"2\" opacity=\".1\"/>
<circle cx=\"18\" cy=\"7\" r=\"2\" fill=\"#fff\"/>
<circle cx=\"18\" cy=\"7\" r=\"1\" fill=\"#323232\"/>
<path d=\"M19 9.67C19 10 17.66 12 16 12s-3-2-3-2.33C13 8.75 14.34 8 16 8s3 .75 3
         1.67z\" fill=\"#eab108\"/>
<path d=\"M25.31 20.03c-.08 0-.16 0-.25.02-.1.03-.16.05-.6.25-.26.13-.5.23-.54
         .24a.99.99 0 0 1-.56 0c-.18-.06-.31.3-.6.11-.2-.13-.42-.3-.58-.33-.21
         -.06-.21-.06-.41-.04a.92.92 0 0 0-.5.2.8.8 0 0 0-.2.24.96.96 0 0 0-.17
         .33c-.12.4-.16.64-.3 1.82-.12.93-.15 1.23-.17 1.65-.02.46-.1 1.22-.16
         1.46l-.11.56-.11.54c-.06.37-.06.74 0 1.1v-.1l.1-.54.12-.56c.05-.24.14-1
         .16-1.46.02-.42.05-.72.17-1.65.14-1.18.18-1.41.3-1.82.05-.16.07-.2.16
         -.33a.8.8 0 0 1 .22-.24c.15-.12.3-.18.49-.2.2-.02.2-.02.41.03.16.05.37
         .21.57.34.3.2.43-.17.6-.12a1 1 0 0 0 .57.01c.04 0 .28-.11.55-.24.43
         -.2.49-.22.6-.25.35-.07.63.02.88.3.07.08.1.11.2.34.11.2.16.33.3.67.21
         .58.04 1.15.17 1.38.24.38.35.64.76.95.24.18.36.3.45.4a.9.9 0 0 0 .14
         -.22.67.67 0 0 0-.06-.7 2.7 2.7 0 0 0-.53-.48c-.4-.3-.52-.57-.76-.95
         -.13-.23.04-.8-.18-1.38a5.88 5.88 0 0 0-.49-1 .88.88 0 0 0-.64-.33z\"
         fill=\"#fff\"
         opacity=\".2\"/>
<path d=\"M23.45 23.05c-1.15 0-1.16-.96-1.39-2.09-.25-1.25-.42-1.98 1.59-2.08
         1.73-.57 2 4.1-.2 4.17z\" fill=\"#4f4f4f\"/>
<path d=\"M16 2c-2.69 0-5 2.5-5 5.6 0 7-4 7.7-4 12.6 0 .18.02.35.03.52C7.28
         16.26 11 15.36 11 8.6 11 5.5 13.31 3 16 3s5 2.5 5 5.6c0 6.76 3.72 7.66
         3.98 12.12l.02-.52c0-4.9-4-5.6-4-12.6C21 4.5 18.69 2 16 2z\"
         fill=\"#fff\"
         opacity=\".1\"/>
<path d=\"M8.86 20c-.47.02-1.05.02-1.34.53-.18.33-.28 1.07-.42 1.2-.15.15-.32.23
         -.54.29l-.55.02c-.51.01-.28.02-.4.05-.37.1-.45.32-.56.72-.03.1-.03-.09
         -.03.19 0 .24.01.4.05.76.1-.36.2-.58.55-.67.1-.03-.12-.04.4-.05.31 0 .5
         -.01.54-.02.22-.06.39-.14.54-.28.14-.14.24-.88.42-1.21.3-.52.87-.51
         1.34-.53.13.03.18.05.32.13a1 1 0 0 1 .32.26c.32.34.48.55 1.2 1.64.57.86
         .74 1.14.97 1.55.25.44.7 1.15.87 1.36l.39.5.37.48c.3.43.53.91.63 1.4.02
         -.07.04-.14.06-.36.02-.23.02-.26-.01-.45a3.79 3.79 0 0 0-.68-1.6l-.37
         -.48-.39-.49c-.17-.21-.62-.92-.87-1.36-.23-.4-.4-.69-.97-1.55-.73-1.1
         -.88-1.3-1.2-1.65a1.06 1.06 0 0 0-.32-.25.86.86 0 0 0-.32-.13zm-3.75
         5.24c-.12.39-.62.58-.83 1.03a2.3 2.3 0 0 0-.27.73c-.03.22.02.42.13.57l
         .14-.3c.23-.5.83-.68.86-1.17.02-.21 0-.5-.03-.86z\"
         fill=\"#fff\"
         opacity=\".2\"/>
</svg>
"
if [ ! -f "${FACE_FILE}" ]; then
echo -e "\n${cyanbold}Set tux user avatar${normal}"
echo -e "$ printf \"%s\" \"\${FACE_TEXT}\" | tee ${FACE_FILE} > /dev/null"
printf "%s" "${FACE_TEXT}" | tee "${FACE_FILE}" > /dev/null
fi

SVG_DIR="/usr/share/plasma/shells/org.kde.plasma.desktop/contents"
SVG_FILE="${SVG_DIR}/kde-plasma.svg"
TASKBAR_DIR="${SVG_DIR}/updates"
TASKBAR_FILE="${TASKBAR_DIR}/plow-taskbar.js"

SVG_TEXT="\
<svg viewBox=\"0 0 44 44\" xmlns=\"http://www.w3.org/2000/svg\">
  <defs>
    <linearGradient
      id=\"a\"
      gradientUnits=\"userSpaceOnUse\"
      x1=\"2\"
      y1=\"2\"
      x2=\"42\"
      y2=\"42\">
      <stop
        offset=\"0\"
        stop-color=\"#2bc0ff\" />
      <stop
        offset=\"1\"
        stop-color=\"#1d99f3\" />
    </linearGradient>
  </defs>
  <rect fill=\"url(#a)\"
    width=\"44\"
    height=\"44\"
    x=\"0\"
    y=\"0\"
    rx=\"5\"
    ry=\"5\" />
  <path fill=\"#fff\"
    d=\"m15 7c-1.108 0-2 0.892-2 2c0 1.108 0.892 2 2 2c1.108 0 2-0.892 2-2c0
       -1.108-0.892-2-2-2zm14 0l-4 4l6 6l-6 6l4 4l6-6l4-4zm-19 12c-1.662 0-3
       1.338-3 3c0 1.662 1.338 3 3 3c1.662 0 3-1.338 3-3c0-1.662-1.338-3-3-3zm9
       12c-2.216 0-4 1.784-4 4c0 2.216 1.784 4 4 4c2.216 0 4-1.784 4-4c0-2.216
       -1.784-4-4-4z\" />
</svg>
"

TASKBAR_TEXT="\
// Remove all existing default panels generated by the global theme
var allPanels = panels();
for (var i = 0; i < allPanels.length; i++) { allPanels[i].remove(); }

// Build the new Plow panel
var taskbar = new Panel();
taskbar.location = \"bottom\";
taskbar.height = 44;
taskbar.floating = 0;

// Kickoff (Start Menu) with custom SVG icon
var kickoff = taskbar.addWidget(\"org.kde.plasma.kickoff\");
kickoff.currentConfigGroup = [\"General\"];
kickoff.writeConfig(\"icon\", \"${SVG_FILE}\");

// Standard Task Manager (Icons + Text, no pinned apps)
var tasks = taskbar.addWidget(\"org.kde.plasma.taskmanager\");
tasks.currentConfigGroup = [\"General\"];
tasks.writeConfig(\"launchers\", \"\");

// Spacer (Expanding pushes subsequent widgets to the right)
var spacer = taskbar.addWidget(\"org.kde.plasma.panelspacer\");

// System Tray (Right-aligned via the spacer)
var systray = taskbar.addWidget(\"org.kde.plasma.systemtray\");

// Digital Clock (Far right edge)
var digitalclock = taskbar.addWidget(\"org.kde.plasma.digitalclock\");
digitalclock.currentConfigGroup = [\"Appearance\"];
digitalclock.writeConfig(\"dateFormat\", \"custom\");
digitalclock.writeConfig(\"customDateFormat\", \"ddd-d-MMM-yyyy\");
digitalclock.writeConfig(\"dateDisplayFormat\", \"BelowTime\");
digitalclock.writeConfig(\"showLocalTimezone\", true);
digitalclock.writeConfig(\"use24hFormat\", 0);
"

if [ ! -f "${SVG_FILE}" ] || \
     ! cmp -s <(printf "%s" "${SVG_TEXT}") "${SVG_FILE}" || \
   [ ! -f "${TASKBAR_FILE}" ] || \
     ! cmp -s <(printf "%s" "${TASKBAR_TEXT}") "${TASKBAR_FILE}"; then

echo -e "\n${cyanbold}Set custom KDE plasma 6 layout${normal}"

# Force regeneration by removing existing config
echo -e "$ rm -f ~/.config/plasma-org.kde.plasma.desktop-appletsrc"
rm -f "${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc"

# Force regeneration by removing updates list
echo -e "$ sed -i '/^\[Updates\]/,/^\[/{ /^\[Updates\]/d; /^\[/!d; }' ~/.config\
/plasmashellrc 2>/dev/null || true"
sed -i '/^\[Updates\]/,/^\[/{ /^\[Updates\]/d; /^\[/!d; }' "${HOME}/.config\
/plasmashellrc" 2>/dev/null || true

# Quietly create directories if needed
sudo mkdir -p "${TASKBAR_DIR}"

# Create taskbar update files
echo -e "$ printf \"%s\" \"\${SVG_TEXT}\" | sudo tee ${SVG_FILE} > /dev/null"
printf "%s" "${SVG_TEXT}" | sudo tee "${SVG_FILE}" > /dev/null
echo -e "$ printf \"%s\" \"\${TASKBAR_TEXT}\" | sudo tee ${TASKBAR_FILE} > \
/dev/null"
printf "%s" "${TASKBAR_TEXT}" | sudo tee "${TASKBAR_FILE}" > /dev/null

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
START_LINE=$(echo "${DPKG_OUTPUT}" | awk '/^\+\+\+-=/ {print NR + 1; exit}')
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
echo -e "$ printf \"%s\" \"\${DUMMY_PAYLOAD}\" | sudo tee ${DUMMY_PKG} > \
/dev/null"
printf "%s" "${DUMMY_PAYLOAD}" | sudo tee "${DUMMY_PKG}" > /dev/null
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
# equivs dependency was installed by script 01

if ! command -v equivs; then
echo -e "  ${redbold}Missing equivs package dependency, exiting${normal}"
exit 105
else
create_dummy_pkg "plasma-nm"
create_dummy_pkg "powerdevil"
create_dummy_pkg "bluedevil"
fi

# Update apt if last `sudo apt update` more than one hour ago

now=$(date +%s)
last_update=$(stat -c %Y /var/cache/apt/pkgcache.bin 2>/dev/null || echo 0)
if ${now} - ${last_update} > 3600; then
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
START_LINE=$(echo "${DPKG_OUTPUT}" | awk '/^\+\+\+-=/ {print NR + 1; exit}')
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

if ! cmp -s <(printf "%s" "${WSLG_VARS}") /etc/environment.d/\
01-graphics-on-wsl.conf; then

echo -e "\n${cyanbold}Setting system-wide environment variables for WSLg\
${normal}"
# Quietly ensure folder exists (but should already be there)
sudo mkdir -p /etc/environment.d

echo -e "$ printf \"%s\" \"\${WSLG_VARS}\" | sudo tee /etc/environment.d/\
01-graphics-on-wsl.conf > /dev/null"
printf "%s" "${WSLG_VARS}" | sudo tee /etc/environment.d/\
01-graphics-on-wsl.conf > /dev/null

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
! cmp -s <(printf "%s" "${kscreenlockerrc}") /etc/xdg/kscreenlockerrc; then
echo -e "\n${cyanbold}Configure kscreenlockerrc${normal}"
echo -e "$ printf \"%s\" \"\${kscreenlockerrc}\" | sudo tee /etc/xdg/\
kscreenlockerrc > /dev/null"
printf "%s" "${kscreenlockerrc}" | sudo tee /etc/xdg/kscreenlockerrc > /dev/null
KDE_CONF_CHANGED=1
fi

if [ ! -f /etc/xdg/kdeglobals ] || \
! cmp -s <(printf "%s" "${kdeglobals}") /etc/xdg/kdeglobals; then
echo -e "\n${cyanbold}Configure kdeglobals${normal}"
echo -e "$ printf \"%s\" \"\${kdeglobals}\" | sudo tee /etc/xdg/kdeglobals > \
/dev/null"
printf "%s" "${kdeglobals}" | sudo tee /etc/xdg/kdeglobals > /dev/null
KDE_CONF_CHANGED=1
fi

if [ ! -f /etc/xdg/ksmserverrc ] || \
! cmp -s <(printf "%s" "${ksmserverrc}") /etc/xdg/ksmserverrc; then
echo -e "\n${cyanbold}Configure ksmserverrc${normal}"
echo -e "$ printf \"%s\" \"\${ksmserverrc}\" | sudo tee /etc/xdg/ksmserverrc > \
/dev/null"
printf "%s" "${ksmserverrc}" | sudo tee /etc/xdg/ksmserverrc > /dev/null
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

# Define systemd unit to fix /tmp/.X11-unix for Xwayland nested in Plow

TMP_X_SERVICE="\
# plow-tmp-x-unix.service
# System service (root) to fix running XWayland nested within a Plow session

[Unit]
Description=Setup writable /tmp/.X11-unix for Xwayland nested in Plow
# Run after systemd has finished configuring local filesystems
After=local-fs.target
# Run before user sessions start
Before=systemd-user-sessions.service

[Service]
# Check mounts are in place before service is Active
Type=notify
# Required so the script (subprocess) can communicate with systemd
NotifyAccess=all
# Service stays 'active' even after the setup script exits
RemainAfterExit=yes
# This is the command to start the service (wrapped in bash)
# Unmount existing if present (ignore errors with || true)
# Mount a writable tmpfs at /tmp/.X11-unix
# Create /tmp/.X11-unix/X0 location
# Mount WSLg as X0 only
# Make X0 read-only (like original WSLg /tmp/.X11-unix mount)
# Check for writable mount, and X0 mounted to WSLg
# Check if parent dir is writable AND X0 is a mountpoint
# Notify ready if check true else error
ExecStart=/bin/bash -c '\
/usr/bin/umount /tmp/.X11-unix 2>/dev/null || true; \
/usr/bin/mount -t tmpfs -o mode=1777,size=1m tmpfs /tmp/.X11-unix && \
/usr/bin/touch /tmp/.X11-unix/X0 && \
/usr/bin/mount --bind /mnt/wslg/.X11-unix/X0 /tmp/.X11-unix/X0 && \
/usr/bin/mount -o remount,ro,bind /tmp/.X11-unix/X0 && \
if [ -w /tmp/.X11-unix ] && /usr/bin/mountpoint -q /tmp/.X11-unix/X0; then \
/usr/bin/systemd-notify --ready; \
else echo \"Error: X11 socket setup failed verification.\" && exit 1; fi'

[Install]
WantedBy=multi-user.target
"

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

TMP_X_UNIT_DIR="/etc/systemd/system"
TMP_X_UNIT_FILE="${TMP_X_UNIT_DIR}/plow-tmp-x-unix.service"
WESTON_UNIT_DIR="/etc/systemd/user"
WESTON_UNIT_FILE="${WESTON_UNIT_DIR}/plow-weston.service"
PLASMA_CONF_DIR="/etc/systemd/user/plasma-kwin_wayland.service.d"
PLASMA_CONF_FILE="${PLASMA_CONF_DIR}/plow-plasma.conf"

# Quietly ensure folders exist
sudo mkdir -p "${PLASMA_CONF_DIR}"

# Configure plow-tmp-x-unix.service systemd unit
if [ ! -f "${TMP_X_UNIT_FILE}" ] || \
! cmp -s <(printf "%s" "${TMP_X_SERVICE}") "${TMP_X_UNIT_FILE}"; then
echo -e "\n${cyanbold}Configure plow-tmp-x-unix.service systemd unit${normal}"
# Choosing to expand path but not file contents in echo output here
# Hence backslash escapes for TMP_X_SERVICE variable
echo -e "$ printf \"%s\" \"\${TMP_X_SERVICE}\" | sudo tee ${TMP_X_UNIT_FILE} > \
/dev/null"
printf "%s" "${TMP_X_SERVICE}" | sudo tee "${TMP_X_UNIT_FILE}" > /dev/null
SYS_UNITS_CHANGED=1
fi

# Configure plow-weston.service systemd unit
if [ ! -f "${WESTON_UNIT_FILE}" ] || \
! cmp -s <(printf "%s" "${WESTON_SERVICE}") "${WESTON_UNIT_FILE}"; then
echo -e "\n${cyanbold}Configure plow-weston.service systemd unit${normal}"
# Choosing to expand path but not file contents in echo output here
# Hence backslash escapes for WESTON_SERVICE variable
echo -e "$ printf \"%s\" \"\${WESTON_SERVICE}\" | sudo tee ${WESTON_UNIT_FILE} \
> /dev/null"
printf "%s" "${WESTON_SERVICE}" | sudo tee "${WESTON_UNIT_FILE}" > /dev/null
USR_UNITS_CHANGED=1
fi

# Configure plasma-kwin_wayland.service customisation
if [ ! -f "${PLASMA_CONF_FILE}" ] || \
! cmp -s <(printf "%s" "${PLASMA_CONF}") "${PLASMA_CONF_FILE}"; then
echo -e "\n${cyanbold}Customise plasma-kwin_wayland systemd unit${normal}"
# Choosing to expand path but not file contents in echo output here
# Hence backslash escapes for PLASMA_CONF variable
echo -e "$ printf \"%s\" \"\${PLASMA_CONF}\" | sudo tee ${PLASMA_CONF_FILE} > \
/dev/null"
printf "%s" "${PLASMA_CONF}" | sudo tee "${PLASMA_CONF_FILE}" > /dev/null
USR_UNITS_CHANGED=1
fi

# Reload systemd if units changed
if [ "${USR_UNITS_CHANGED}" -eq 1 ]; then
echo -e "\n${cyanbold}Reload systemd user daemon${normal}"
echo -e "$ systemctl --user daemon-reload"
systemctl --user daemon-reload
fi
if [ "${SYS_UNITS_CHANGED}" -eq 1 ]; then
echo -e "\n${cyanbold}Reload systemd system daemon${normal}"
echo -e "$ sudo systemctl daemon-reload"
sudo systemctl daemon-reload
echo -e "$ sudo systemctl enable --now plow-tmp-x-unix.service"
sudo systemctl enable --now plow-tmp-x-unix.service
fi

# Show all systemd units in context (existing along with new plow & plasma)
echo -e "\n${cyanbold}Listing all available systemd user unit-files${normal}"
echo -e "$ systemctl --user list-unit-files --no-pager\n"
systemctl --user list-unit-files --no-pager

# create sps (start plow session) command at /usr/bin/sps

SPS_FILE="/usr/bin/sps"
SPS_TEXT="\
#!/bin/bash
if ! systemctl --user is-active plasma-workspace.target > /dev/null
then startplasma-wayland & disown
fi
"

echo -e "\n${cyanbold}Configure /usr/bin/sps (Start Plow Session)${normal}"
if ! command -v sps &> /dev/null; then
echo -e "$ printf \"%s\" \"\${SPS_TEXT}\" | sudo tee ${SPS_FILE} > /dev/null"
printf "%s" "${SPS_TEXT}" | sudo tee "${SPS_FILE}" > /dev/null
echo -e "$ sudo chmod +x ${SPS_FILE}"
sudo chmod +x "${SPS_FILE}"
echo -e "${bluebold}Command within /usr/bin/sps is:"
echo -e "${cyanbold}if ! systemctl --user is-active plasma-workspace.target > \
/dev/null; then startplasma-wayland & disown; fi"
else
echo -e "> /usr/bin/sps already exists"
fi

# create eps (end plow session) command at /usr/bin/eps

EPS_FILE="/usr/bin/eps"
EPS_TEXT="\
#!/bin/bash
qdbus6 org.kde.LogoutPrompt /LogoutPrompt org.kde.LogoutPrompt.promptLogout
"

echo -e "\n${cyanbold}Configure /usr/bin/eps (End Plow Session)${normal}"
if ! command -v eps &> /dev/null; then
echo -e "$ printf \"%s\" \"\${EPS_TEXT}\" | sudo tee ${EPS_FILE} > /dev/null"
printf "%s" "${EPS_TEXT}" | sudo tee "${EPS_FILE}" > /dev/null
echo -e "$ sudo chmod +x ${EPS_FILE}"
sudo chmod +x "${EPS_FILE}"
echo -e "${bluebold}Command within /usr/bin/eps is:"
echo -e "${cyanbold}qdbus6 org.kde.LogoutPrompt /LogoutPrompt \
org.kde.LogoutPrompt.promptLogout${normal}"
else
echo -e "> /usr/bin/eps already exists"
fi

# Run plow-plasma.service
echo -e "\n${cyanbold}Run Plow session${normal}"
echo -e "$ if ! systemctl --user is-active plasma-workspace.target > /dev/null; \
then startplasma-wayland & disown; fi"
if ! systemctl --user is-active plasma-workspace.target > /dev/null; \
then startplasma-wayland & disown; \
fi

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

