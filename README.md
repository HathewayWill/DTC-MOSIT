### DTC Suite Multi Operational System Install Toolkit
This is a BASH script that provides options to install the following DTC packages in 64-bit systems:

- MET v11.1.1
- METplus v5.1.0
---
### System Requirements
- 64-bit system
    - Linux Debian Distro (Ubuntu, Mint, etc)
    - Windows Subsystem for Linux (Debian Distro, Ubuntu, Mint, etc)
    - Linux Fedora Distro
    - MacOS

### MacOS Installation
- Make sure to download and Homebrew before moving to installation.
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

> brew install git

> git clone https://github.com/HathewayWill/DTC-MOSIT.git

> cd $HOME/DTC-MOSIT

> chmod 775 *.sh

> ./DTC-MOSIT.sh 2>&1 | tee DTC_MOSIT.log

### APT Installation
- (Make sure to download folder into your Home Directory):
> cd $HOME

> sudo apt install git -y

> git clone https://github.com/HathewayWill/DTC-MOSIT.git

> cd $HOME/DTC-MOSIT

> chmod 775 *.sh

> ./DTC-MOSIT.sh 2>&1 | tee DTC_MOSIT.log


### YUM/DNF Installation
- (Make sure to download folder into your Home Directory):
> cd $HOME

> sudo (yum or dnf) install git -y

> git clone https://github.com/HathewayWill/DTC-MOSIT.git

> cd $HOME/DTC-MOSIT

> chmod 775 *.sh

> ./DTC_MOSIT.sh 2>&1 | tee DTC_MOSIT.log

- Script will check for System Architecture Type and Storage Space requirements.

--

  ##### *** Tested on Ubuntu 22.04.4 LTS, Ubuntu 24.04.1 LTS, MacOS Ventura, MacOS Sonoma, Centos7, Rocky Linux 9, Windows Sub-Linux Ubuntu***
- Built 64-bit system.

---
#### Estimated Run Time ~ 10 to 30 Minutes @ 10mbps download speed.

---
### Special thanks to:
- Youtube's meteoadriatic
- GitHub user jamal919
- DTC's Julie P., Tara J., George M., & John H.
---
#### Citation:
#### Hatheway, W. (2024). DTC MET Multi Operational System Install Toolkit (Version 1.2) [Computer software]
