# **Plow** _(\[KDE\] P̳l̳asma o̳n W̳SLg)_

## Introduction
 - **Plow** _(\[KDE\] P̳l̳asma o̳n W̳SLg)_ is a {wslg > weston > kde-plasma} nested desktop environment.
 - Plow is strictly just `05-configure-plow-WSL-Debian.sh`; the other files in this repo are my other dotfiles for running Debian on WSL2.
 - Better developers & maintainers than me have said; _"It would be much better if most derivative distro projects were just a configuration script on top of the parent distro"_; so that is what this project is.
 - The use case / manifesto for Plow (& Configure WSL dotfiles) is:  _"I am required to work on a Windows laptop at work, but I have local admin for said Windows laptop, and I can use the WSL Windows component.  Let's turn Debian on WSL into the best possible native Windows application window, containing a full, graphical KDE-based Linux environment."_

## Development Model & Licence _(spelling not a typo in my locale)_
 - It is a shame I need to put licence considerations, and guidance for interacting with this project, so high up in this `README` file.
 - Release 0.1 was developed with extensive assistance from Gemini 3.0 Pro only.
 - For Release 0.1, the original author notes that Gemini 3.0 Pro, was NOT able to get to the successful working nested desktop you see when running this project, without extensive human oversight from the original author.  This was 100% getting stuck in troubleshooting loops choosing implementation routes that errored out, and not being able to try a new solution rather than loop, without a new human suggestion.  Gemini has the basics of writing high-quality, idempotent bash, 100% nailed though.  I'm sure the git commit history can give you some more insight, for interested parties.
 - Future releases may be developed with assistance from other LLMs, including but not limited to Gemini 3.1 Pro, without any further updates to this `README`, explaining what they are/were.
 - Therefore, due to the material human choices around system architecture encoded into this project (including but not limited to, desktop environment nesting, and systemd configuration choices), the original author claims copyright to this work, to the maximum extent allowed in law, both in the author's jurisdiction of residence, and in any/each juridiction that this code is re-used.
 - However, the original author does consider this code "tainted", per the definition set by NetBSD commit guidelines, for AI influence.  This term is being borrowed from NetBSD (thank you) as a well-thought-though definition, rather than any suggestion that this project has any relevance to NetBSD.
 - The original author uses his copyright claim, to release the full contents of this repo under the MIT-0 licence.
 - The author is also aware that legal arguments exist in some jurisdictions, which mean simple configuration, such as bash scripts, might not be copyrightable.
 - Regardless of whether it is based in copyright law, or just contractual terms of use, the lack of any warranty is what is strictly enforced from the MIT-0 licence, from the moment that you and/or your AI assistant first read or ingesting any part of this GitHub repo.
 - Basically, please don't sue the project owner, or original author, over any contents of this repo.  For anyone who does sue (or issues a takedown), the pre-emptive arguments to have the matter thrown out, are (i) this project is 100% simple bash config only, so you had no valid copyright claim over any original content that pre-existed this repo, and (ii) there is explicitly no warranty, so any action in contract, tort or otherwise, has no legal basis.
 - The original author does sincerely sympathise with all developers who think a formal code-of-conduct for a small personal project is overkill.  However, with the level of nastiness and hurt that can occur with just some ill-chosen words posted online, I do ask anyone submitting an issue or pull request to this project (if/when I open such functionality), to please respect the following guidance:
     - Please at minimum, (i) check for error-free excution of the script on a current version of Windows 11, and (ii) put any bash code submitted into the same style as the rest of the scripts commited within the project; this is what the original author does for each commit at minimum.
     - You can be as blunt as you like about technical matters (only).  The following format is always okay:  `W (quoted code)` is technically wrong because `X (technical reasoning only)` and `Y (replacement code)` fixes this because `Z (more technical reasons)`.
     - Otherwise, please just try to be respectful to all other code contributors.  We are all volunteering to commit the best possible code we can, in limited spare time - please treat our efforts accordingly.
     - The project owner(s) (original author now, or perhaps other(s) later) will reject issues / pull requests to this project, where, in the project owner's sole judgement, the commit does not demonstrate effective human oversight, or contains disrespectful language.
     - If others have forked this repository, without editing this `README` file, you should assume that this guidance applies for issues / pull requests against their project fork, too.

## Idiosyncracies
 - I use 1password for my secrets management; this is heavily integrated into the scripts.
 - I have a custom AU locale, a gb/uk keyboard, and Brisbane timezone, all in `04-keyboard-timezone-locale-WSL-Debian.sh`.  This shows you how I manage the warring configurations of Debian (debconf) vs. systemd, but you will likely want to fork and set your own preferences there.
 - For better or worse this is a wayland project.  X11 programs may work via Xwayland, but this is not actively tested.  Yes, X11 / X.org, with its client-server model, would objectively be a better architectural choice for this use case, but Microsoft builds and maintains the [WSLg](https://github.com/microsoft/wslg?tab=readme-ov-file#wslg-architecture-overview) (Wayland plus FreeRDP) based graphics pipeline, in this environment.  This project exists to explore how-to use that Microsoft-provided graphics pipeline, as well as we can, for a KDE Plasma session, in a native Windows application window.
 - For better or worse this is a systemd project.  Systemd is the only init system for which Microsoft builds and develops integrations and quality-of-life improvements, for Windows Subsystem for Linux (WSL) guests.  This project exists to see how good a KDE Plasma session (in a native Windows application window), we can provide, when utilising these Microsoft-provided Windows services.
 - The other weirdness in this environment is graphics acceleration.  WSL2 uses Mesa d3d12 and dxgkrnl for this.  The primary target for these scripts is a Surface Laptop Studio 2 (SLS2) with Intel & Nvidia (GeForce RTX 4050) graphics.  This project targets the Nvidia graphics acceleration.  Fork and edit script(s) to target other hardware.  This project exists to explore how-to use these Microsoft-provided graphics drivers, as well as we can, for a KDE Plasma session, in a native Windows application window.
 - For better or worse this project uses Debian as the WSL client.  The debian packaging system is powerful and familiar to the project's author.  Debian still prioritises use of deb packages, rather than prioritising containerised alternatives (snap, flatpak, etc.) like Ubuntu et al, which the project author appreciates.  Debian is widely supported, with third-party repos for the author's preferred commercial tools (most importantly 1Password & NordVPN).

## Configuration Instructions

1. Install required Windows software
    ```
    winget install -e --id Microsoft.WindowsTerminal
    ```
    ```
    winget install -e --id Microsoft.WSL
    ```
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
> Known issues:
>   - _TO-DO: Document here what the script does.  `05-configure-plow-WSL-Debian.sh` sets up everything._
>   - _TO-DO: Plow command in WSL CLI launches the nested desktop environment._
>   - _TO-DO: Config to make Plow with an app icon show up in Windows start menu._
>   - _Cursor ghosting a known issue.  TO-DO: Apply invisible cursor theme to remove one of the stacked cursors._
>   - _Weston 16 has just been released, with lua scripted shell option.  TO-DO: This could be a way for the Weston window to have minimise and maximise buttons, not just close button (with Win+Arrow and Ctrl+Alt+F keyboard shortcuts heavily relied upon, currently, to manipulate window size)._

`TO-DO: More about 05-configure-plow-WSL-Debian.sh here...`
