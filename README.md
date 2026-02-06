# **Plow** _(\[KDE\] P̳l̳asma o̳n W̳SLg)_

## Introduction
 - **Plow** _(\[KDE\] P̳l̳asma o̳n W̳SLg)_ is a {wslg > weston > kde-plasma} nested desktop environment.
 - Plow is strictly just `05-configure-plow-WSL-Debian.sh`; the other files in this repo are my other dotfiles for running Debian on WSL2.
 - Better developers & maintainers than me have said _"It would be much better if most derivative distro projects were just a configuration script on top of the parent distro"_, so that is what this project is.
 - The use case / manifesto for Plow (& Configure WSL dotfiles) is:  _"I am required to work on a Windows laptop at work, but I have local admin for said Windows laptop, and I can use the WSL Windows component.  Let's turn Debian on WSL into the best possible native Windows application window, containing a full, graphical KDE-based Linux environment."_

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
    echo "if [ \"\$(wget -V 2> /dev/null | head -c 8)\" != \"GNU Wget\" ]; \\
    then \
    echo -e \"\n\$(printf '\033[96;1m')Installing wget\$(printf '\033[0m')\" \\
    && echo -e \"\$ sudo apt update && sudo apt -y install wget\n\" \\
    && sudo apt update && sudo apt -y install wget \\
    && echo -e \"\n\$(printf '\033[92;1m')wget successfully installed\
    \$(printf '\033[0m')\n\"; \\
    else \\
    echo -e \"\n\$(printf '\033[92;1m')wget already installed\
    \$(printf '\033[0m')\n\"; \\
    fi" | bash
    ```
    _Configure repos & update packages_
    ```
    wget -qO- https://raw.githubusercontent.com/phil-gg/configure-wsl2/main/01-configure-repos-update-pkgs-WSL-Debian.sh | bash
    ```
    _Configure git (same script also updates git)_
    ```
    wget -qO- https://raw.githubusercontent.com/phil-gg/configure-wsl2/main/02-configure-git-WSL-Debian.sh | bash
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

## Graphical option #2: Run {wslg > weston > kde-plasma} nested desktop environment

> [!NOTE]  
>   - _Work in progress: `05-configure-plow-WSL-Debian.sh` sets up everything._
>   - _TO-DO: Plow command in WSL CLI launches the nested desktop environment._
>   - _TO-DO: Config to make Plow with an app icon show up in Windows start menu._
>   - _Cursor ghosting a known issue.  TO-DO: Apply invisible cursor theme to remove one of the stacked cursors._

`TO-DO: Document config`
