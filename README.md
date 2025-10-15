# Instructions for use

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
    _Unregister or uninstall a Linux distribution:_
    ```
    wsl.exe --unregister <DistributionName>
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
    wget -qO- https://raw.githubusercontent.com/phil-gg/configure-wsl2/main/01-configure-repos-update-dpkg-WSL-Debian.sh | bash
    ```
    _Configure git (same script also updates git)_
    ```
    work in progress
    ```

## Graphical option #1: launch GUI linux app directly in a wslg window

TO-DO: Document with firefox example

## Graphical option #2: Run gnome-shell nested in a wslg window

> [!NOTE]  
>   - _Application windows can sometimes be slow to open in the nested gnome session_
>   - _No fullscreen, with window resolution set by launch script_
>   - _Cursor ghosting a known issue (host Windows cursor over guest Gnome cursor)_
>   - _Use this graphical session in RDP set-up step for_ `gnome-control-center` _steps not yet moved to CLI / script_

TO-DO: Document config

## Graphical option #3: RDP session from Windows host into Debian on WSL

TO-DO: Both actually get it running(!) and document
