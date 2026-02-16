# **Plow** _(\[KDE\] P̳l̳asma o̳n W̳SLg)_

## Introduction
 - **Plow** _(\[KDE\] P̳l̳asma o̳n W̳SLg)_ is a {wslg > weston > kde-plasma} nested desktop environment.
 - Plow is strictly just `05-configure-plow-WSL-Debian.sh`; the other files in this repo are my other dotfiles for running Debian on WSL2.
 - Better developers & maintainers than me have said; _"It would be much better if most derivative distro projects were just a configuration script on top of the parent distro"_; so that is what this project is.
 - The use case / manifesto for Plow (& Configure WSL dotfiles) is:  _"I am required to work on a Windows laptop at work, but I have local admin for said Windows laptop, and I can use the WSL Windows component.  Let's turn Debian on WSL into the best possible native Windows application window, containing a full, graphical KDE-based Linux environment."_

## Idiosyncracies
 - I use 1password for my secrets management; this is heavily integrated into the scripts.
 - I have a custom AU locale, a gb/uk keyboard, and Brisbane timezone, all in `04-keyboard-timezone-locale-WSL-Debian.sh`.  This shows you how I manage the warring configurations of Debian (debconf) vs. systemd, but you will likely want to fork and set your own preferences there.
 - For better or worse this is a wayland project.  X11 programs may work via Xwayland, but this is not actively tested.  Yes, X11 / X.org, with its client-server model, would objectively be a better architectural choice for this use case, but Microsoft builds and maintains the [WSLg](https://github.com/microsoft/wslg?tab=readme-ov-file#wslg-architecture-overview) (Wayland plus FreeRDP) based graphics pipeline, in this environment.  This project exists to explore how-to use that Microsoft-provided graphics pipeline, as well as we can, for a KDE Plasma session, in a native Windows application window.
 - For better or worse this is a systemd project.  Systemd is the only init system for which Microsoft builds and develops integrations and quality-of-life improvements, for Windows Subsystem for Linux (WSL) guests.  This project exists to see how good a KDE Plasma session (in a native Windows application window), we can provide, when utilising these Microsoft-provided Windows services.
 - For better or worse this project uses Debian as the WSL client.  The debian packaging system is powerful and familiar to the project's author.  Debian still prioritises use of deb packages, rather than prioritising containerised alternatives (snap, flatpak, etc.) like Ubuntu et al, which the project author appreciates.  Debian is widely supported, with third-party repos for the author's preferred commercial tools (most importantly 1Password & NordVPN).
 - The other weirdness in this environment is graphics acceleration.  WSL2 uses Mesa d3d12 and dxgkrnl for this.  The primary target for these scripts is a Surface Laptop Studio 2 (SLS2) with Intel & Nvidia (GeForce RTX 4050) graphics.  This project targets the Nvidia graphics acceleration.  Fork and edit script(s) to target other hardware.

## Configuration Instructions

1. Install WSL on Windows host
    ```
    wsl.exe --install --no-distribution --web-download
    ```

2. Configure Linux on WSL

    _The below commands are sourced from:_
    ```
    wsl.exe --help
    ```
    _Update WSL:_
    ```
    wsl.exe --update
    ```
    _List distros pre-packaged for WSL:_
    ```
    wsl.exe --list --online
    ```
    _List distros you have installed on WSL (and their current state):_
    ```
    wsl.exe --list --verbose
    ```
    _Unregister or uninstall a Linux distribution (Debian example):_
    ```
    wsl.exe --unregister Debian
    ```
    _Install Debian on WSL:_
    ```
    wsl.exe --install Debian --web-download
    ```
    _Set Debian as default distro on WSL:_
    ```
    wsl.exe --set-default Debian
    ```
    _Set WSL2 as default:_
    ```
    wsl.exe --set-default-version 2
    ```
    _Check the default distro and version WSL options you have just set:_
    ```
    wsl.exe --status
    ```
    _Powershell command to show the properties of your WSL installation:_
    ```
    pwsh.exe -Command Get-ChildItem "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
    ```
    _In WSL CLI only (i.e. run in Debian), keep just '{GUID}' for your WSL installation:_
    ```
    pwsh.exe -Command Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss" | grep -o -e "{[^}]*}"
    ```
    _Shutdown instance from WSL CLI (e.g. to update Windows Terminal config and relaunch):_
    ```
    wsl.exe --shutdown
    ```
    _Command to launch WSL distro in Windows Terminal_
    ```
    C:\WINDOWS\system32\wsl.exe --distribution-id {GUID} --cd ~
    ```
    _Set default user login for WSL distro (this user must exist, typically created during OOBE):_
    ```
    wsl.exe --manage Debian --set-default-user phil
    ```
    _Set vhdx to sparse, so unused disk space is automatically reclaimed:_
    ```
    wsl.exe --manage Debian --set-sparse true --allow-unsafe
    ```
    _Windows files are available in Linux at:_
    ```
    /mnt/c/
    ```
    _Linux files are available in Windows at:_
    ```
    \\wsl.localhost\Debian
    ```

3. Configure Debian

    _Manage dependency on wget_
    ```
    printf "\n\e[96;1mInstalling wget\e[0m
    $ sudo apt update && sudo apt -y install wget\n\n" && \
    { sudo apt update && sudo apt -y install wget && \
    printf "\n\e[92;1mwget successfully installed\e[0m\n\n"; } || \
    printf "\n\e[91;1mWarning: Error when installing wget\e[0m\n\n"
    ```
    _Configure repos & update packages_
    ```
    wget -qO- https://raw.githubusercontent.com/phil-gg/configure-wsl2/main/01-configure-repos-update-pkgs-WSL-Debian.sh | bash
    ```
    _Configure git_
    ```
    wget -qO- https://raw.githubusercontent.com/phil-gg/configure-wsl2/main/02-configure-git-WSL-Debian.sh | bash
    ```
    _Clone / sync git_
    ```
    wget -qO- https://raw.githubusercontent.com/phil-gg/configure-wsl2/main/03-sync-git-WSL-Debian.sh | bash
    ```
    _Now scripts can be run locally_
    ```
    cd ~/git/phil-gg/configure-wsl2
    ```
    ```
    cat 01-configure-repos-update-pkgs-WSL-Debian.sh | bash
    ```
    ```
    cat 02-configure-git-WSL-Debian.sh | bash
    ```
    ```
    cat 03-sync-git-WSL-Debian.sh | bash
    ```
    ```
    cat 04-keyboard-timezone-locale-WSL-Debian.sh | bash
    ```
    ```
    cat 05-configure-plow-WSL-Debian.sh | bash
    ```
    _etc._

## Graphical option #1: launch GUI linux app directly in a wslg window

4. Once you have run `01-configure-repos-update-pkgs-WSL-Debian.sh`, you can run `firefox-devedition` or `1password` by launching from WSL CLI:

    ```
    firefox-devedition
    ```
    ```
    1password
    ```
    ```
    foot
    ```
    _These apps should also be available from Windows start menu with a ` (Debian)` suffix_

## Graphical option #2: Run Plow nested desktop environment

> [!NOTE]  
>   - _Work in progress: `05-configure-plow-WSL-Debian.sh` sets up everything._
>   - _TO-DO: Plow command in WSL CLI launches the nested desktop environment._
>   - _TO-DO: Config to make Plow with an app icon show up in Windows start menu._
>   - _Cursor ghosting a known issue.  TO-DO: Apply invisible cursor theme to remove one of the stacked cursors._

`TO-DO: Document config`
