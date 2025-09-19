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
    _Set default user login for WSL distro (this user must exist, typically created during OOBE):_
    ```
    wsl.exe --manage Debian --set-default-user phil
    ```
    _Set vhdx to sparse, so unused disk space is automatically reclaimed:_
    ```
    wsl.exe --manage Debian --set-sparse true --allow-unsafe
    ```

4. Configure Debian for graphical use

## First enable use of gnome-shell in a wslg window

> [!NOTE]  
>   - Application windows can sometimes be slow to open in the nested gnome session
>   - No fullscreen, with window resolution set by launch script
>   - Cursor ghosting a known issue (host Windows cursor over guest Gnome cursor)
>   - Use this graphical session in RDP set-up step for `gnome-control-center` steps not yet moved to CLI / script

_Run the following commands in Debian WSL CLI:_

```
foo
```

## Second enable RDP graphical session for Debian on WSL
