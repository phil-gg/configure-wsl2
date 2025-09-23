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
    _In WSL CLI, keep just '{GUID}' for your WSL installation:_
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

    _Update Debian_
    ```
    sudo apt update && sudo apt upgrade
    ```
    _Install wget_
    ```
    sudo apt install wget
    ```
    _Configure git_
    ```
    wget -qO - https://raw.githubusercontent.com/phil-gg/configure-wsl2/main/01-configure-git-WSL-Debian.sh | bash
    ```
    _Update git (subsequent uses of 'configure-wsl2' only)_
    ```
    cd ~/git/phil-gg/configure-wsl2/ && ./02-update-git-WSL-Debian.sh
    ```

## Graphical option #1: launch GUI linux app directly in a wslg window

TO-DO: Document with firefox example

## Graphical option #2: Run gnome-shell nested in a wslg window

> [!NOTE]  
>   - Application windows can sometimes be slow to open in the nested gnome session
>   - No fullscreen, with window resolution set by launch script
>   - Cursor ghosting a known issue (host Windows cursor over guest Gnome cursor)
>   - Use this graphical session in RDP set-up step for `gnome-control-center` steps not yet moved to CLI / script

TO-DO: Document config

## Graphical option #3: RDP session from Windows host into Debian on WSL

TO-DO: Both actually get it running(!) and document
