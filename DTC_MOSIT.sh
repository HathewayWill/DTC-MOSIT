#!/bin/bash

# Conda Environment Test
if [ -n "$CONDA_DEFAULT_ENV" ]; then
	echo "CONDA_DEFAULT_ENV is active: $CONDA_DEFAULT_ENV"
	echo "Turning off $CONDA_DEFAULT_ENV"
	conda deactivate
	conda deactivate
else
	echo "CONDA_DEFAULT_ENV is not active."
	echo "Continuing script"
fi

# Exporting versions for MET and METPLUS
export METPLUS_Version=6.2.0
export met_Version_number=12.2.0
export met_VERSION_number=12.2
export METPLUS_DATA=6.2

# Capture the start time for logging or performance measurement
start=$(date)
START=$(date +"%s")

############################### Citation Requirement  ####################
echo " "
echo " The GitHub software WRF-MOSIT (Version 2.1.1) by W. Hatheway (2023)"
echo " "
echo "It is important to note that any usage or publication that incorporates or references this software must include a proper citation to acknowledge the work of the author."
echo " "
echo -e "This is not only a matter of respect and academic integrity, but also a \e[31mrequirement\e[0m set by the author. Please ensure to adhere to this guideline when using this software."
echo " "
echo -e "\e[31mCitation: Hatheway, W., Snoun, H., ur Rehman, H., & Mwanthi, A. WRF-MOSIT: a modular and cross-platform tool for configuring and installing the WRF model [Computer software]. https://doi.org/10.1007/s12145-023-01136-y]\e[0m"

echo " "
read -p "Press enter to continue"

############################### System Architecture Type #################
# Determine if the system is 32 or 64-bit based on the architecture
##########################################################################
export SYS_ARCH=$(uname -m)

if [ "$SYS_ARCH" = "x86_64" ] || [ "$SYS_ARCH" = "arm64" ]; then
	export SYSTEMBIT="64"
else
	export SYSTEMBIT="32"
fi

# Determine the chip type if on macOS (ARM or Intel)
if [ "$SYS_ARCH" = "arm64" ]; then
	export MAC_CHIP="ARM"
else
	export MAC_CHIP="Intel"
fi

############################# System OS Version #############################
# Detect if the OS is macOS or Linux
#############################################################################
export SYS_OS=$(uname -s)

if [ "$SYS_OS" = "Darwin" ]; then
	export SYSTEMOS="MacOS"
	# Get the macOS version using sw_vers
	export MACOS_VERSION=$(sw_vers -productVersion)
	echo "Operating system detected: MacOS, Version: $MACOS_VERSION"
elif [ "$SYS_OS" = "Linux" ]; then
	export SYSTEMOS="Linux"
fi

########## RHL and Linux Distribution Detection #############
# More accurate Linux distribution detection using /etc/os-release
#################################################################
if [ "$SYSTEMOS" = "Linux" ]; then
	if [ -f /etc/os-release ]; then
		# Extract the distribution name and version from /etc/os-release
		export DISTRO_NAME=$(grep -w "NAME" /etc/os-release | cut -d'=' -f2 | tr -d '"')
		export DISTRO_VERSION=$(grep -w "VERSION_ID" /etc/os-release | cut -d'=' -f2 | tr -d '"')

		# Print the distribution name and version
		echo "Operating system detected: $DISTRO_NAME, Version: $DISTRO_VERSION"

		# Check if the system is RHL based on /etc/os-release
		if grep -q "RHL" /etc/os-release; then
			export SYSTEMOS="RHL"
		fi

		# Check if dnf or yum is installed (dnf is used on newer systems, yum on older ones)
		if command -v dnf >/dev/null 2>&1; then
			echo "dnf is installed."
			export SYSTEMOS="RHL" # Set SYSTEMOS to RHL if dnf is detected
		elif command -v yum >/dev/null 2>&1; then
			echo "yum is installed."
			export SYSTEMOS="RHL" # Set SYSTEMOS to RHL if yum is detected
		else
			echo "No package manager (dnf or yum) found."
		fi
	else
		echo "Unable to detect the Linux distribution version."
	fi
fi

# Print the final detected OS
echo "Final operating system detected: $SYSTEMOS"

############################### Intel or GNU Compiler Option #############

# Only proceed with RHL-specific logic if the system is RHL
if [ "$SYSTEMOS" = "RHL" ]; then
	# Check for 32-bit RHL system
	if [ "$SYSTEMBIT" = "32" ]; then
		echo "Your system is not compatible with this script."
		exit
	fi

	# Check for 64-bit RHL system
	if [ "$SYSTEMBIT" = "64" ]; then
		echo "Your system is a 64-bit version of RHL Linux Kernel."

		# Check if RHL_64bit_Intel or RHL_64bit_GNU environment variables are set
		if [ -n "$RHL_64bit_Intel" ] || [ -n "$RHL_64bit_GNU" ]; then
			echo "The environment variable RHL_64bit_Intel/GNU is already set."
		else
			echo "The environment variable RHL_64bit_Intel/GNU is not set."

			# Prompt user to select a compiler (Intel or GNU)
			while read -r -p "Which compiler do you want to use?
                - Intel
                - GNU
                Please answer Intel or GNU and press enter (case-sensitive): " yn; do
				case $yn in
				Intel)
					echo "Intel is selected for installation."
					export RHL_64bit_Intel=1
					break
					;;
				GNU)
					echo "GNU is selected for installation."
					export RHL_64bit_GNU=1
					break
					;;
				*)
					echo "Please answer Intel or GNU (case-sensitive)."
					;;
				esac
			done
		fi

		# Check for the version of the GNU compiler (gcc)
		if [ -n "$RHL_64bit_GNU" ]; then
			export gcc_test_version=$(gcc -dumpversion 2>&1 | awk '{print $1}')
			export gcc_test_version_major=$(echo $gcc_test_version | awk -F. '{print $1}')
			export gcc_version_9="9"

			if [[ $gcc_test_version_major -lt $gcc_version_9 ]]; then
				export RHL_64bit_GNU=2
				echo "OLD GNU FILES FOUND."
				echo "RHL_64bit_GNU=$RHL_64bit_GNU"
			fi
		fi
	fi
fi

# Check for 64-bit Linux system (Debian/Ubuntu)
if [ "$SYSTEMBIT" = "64" ] && [ "$SYSTEMOS" = "Linux" ]; then
	echo "Your system is a 64-bit version of Debian Linux Kernel."
	echo ""

	# Check if Ubuntu_64bit_Intel or Ubuntu_64bit_GNU environment variables are set
	if [ -n "$Ubuntu_64bit_Intel" ] || [ -n "$Ubuntu_64bit_GNU" ]; then
		echo "The environment variable Ubuntu_64bit_Intel/GNU is already set."
	else
		echo "The environment variable Ubuntu_64bit_Intel/GNU is not set."

		# Prompt user to select a compiler (Intel or GNU)
		while read -r -p "Which compiler do you want to use?
            - Intel
            -- Please note that WRF_CMAQ is only compatible with GNU Compilers
            - GNU
            Please answer Intel or GNU and press enter (case-sensitive): " yn; do
			case $yn in
			Intel)
				echo "Intel is selected for installation."
				export Ubuntu_64bit_Intel=1
				break
				;;
			GNU)
				echo "GNU is selected for installation."
				export Ubuntu_64bit_GNU=1
				break
				;;
			*)
				echo "Please answer Intel or GNU (case-sensitive)."
				;;
			esac
		done
	fi
fi

# Check for 32-bit Linux system
if [ "$SYSTEMBIT" = "32" ] && [ "$SYSTEMOS" = "Linux" ]; then
	echo "Your system is not compatible with this script."
	exit
fi

############################# macOS Handling ##############################

# Check for 32-bit MacOS system
if [ "$SYSTEMBIT" = "32" ] && [ "$SYSTEMOS" = "MacOS" ]; then
	echo "Your system is not compatible with this script."
	exit
fi

# Check for 64-bit Intel-based MacOS system
if [ "$SYSTEMBIT" = "64" ] && [ "$SYSTEMOS" = "MacOS" ] && [ "$MAC_CHIP" = "Intel" ]; then
	echo "Your system is a 64-bit version of macOS with an Intel chip."
	echo "Intel compilers are not compatible with this script."
	echo "Setting compiler to GNU."
	export macos_64bit_GNU=1

	# Ensure Xcode Command Line Tools are installed
	if ! xcode-select --print-path &>/dev/null; then
		echo "Installing Xcode Command Line Tools..."
		xcode-select --install

		# Add a loop to wait for the installation to be completed
		echo "Waiting for Xcode Command Line Tools to install. Please follow the installer prompts..."
		while ! xcode-select --print-path &>/dev/null; do
			sleep 5 # Wait for 5 seconds before checking again
		done

		echo "Xcode Command Line Tools installation confirmed."
	fi

	# Install Homebrew for Intel Macs in /usr/local
	echo "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	echo 'eval "$(/usr/local/bin/brew shellenv)"' >>~/.profile
	eval "$(/usr/local/bin/brew shellenv)"

	chsh -s /bin/bash
fi

# Check for 64-bit ARM-based MacOS system (M1, M2 chips)
if [ "$SYSTEMBIT" = "64" ] && [ "$SYSTEMOS" = "MacOS" ] && [ "$MAC_CHIP" = "ARM" ]; then
	echo "Your system is a 64-bit version of macOS with an ARM chip (M1/M2)."
	echo "Intel compilers are not compatible with this script."
	echo "Setting compiler to GNU."
	export macos_64bit_GNU=1

	# Ensure Xcode Command Line Tools are installed
	if ! xcode-select --print-path &>/dev/null; then
		echo "Installing Xcode Command Line Tools..."
		xcode-select --install

		# Add a loop to wait for the installation to be completed
		echo "Waiting for Xcode Command Line Tools to install. Please follow the installer prompts..."
		while ! xcode-select --print-path &>/dev/null; do
			sleep 5 # Wait for 5 seconds before checking again
		done

		echo "Xcode Command Line Tools installation confirmed."
	fi

	# Install Homebrew for ARM Macs in /opt/homebrew
	echo "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.profile
	eval "$(/opt/homebrew/bin/brew shellenv)"

	chsh -s /bin/bash
fi

################### System Information Tests ##############################

echo ""
echo "--------------------------------------------------"
echo "Testing for storage space for installation."

HOME_DIR="${HOME}"
REQUIRED_BYTES=$((350 * 1024 * 1024 * 1024)) # 350GB in bytes

# Get available space in bytes (use -B1 for bytes)
AVAILABLE_BYTES=$(df -B1 --output=avail "$HOME_DIR" | awk 'NR==2')

# Convert for human-readable printing
AVAILABLE_HR=$(numfmt --to=iec "$AVAILABLE_BYTES")
REQUIRED_HR=$(numfmt --to=iec "$REQUIRED_BYTES")

if ((AVAILABLE_BYTES < REQUIRED_BYTES)); then
	echo -e "\e[31mNot enough storage space for installation. $REQUIRED_HR is required.\e[0m"
	echo -e "\e[31mStorage Space Available: $AVAILABLE_HR\e[0m"
	exit 1
else
	echo "Sufficient storage space for installation found: $AVAILABLE_HR"
fi

echo "--------------------------------------------------"
############################# Enter sudo users information #############################
echo "-------------------------------------------------- "
while true; do
	# Prompt for the initial password
	read -r -s -p "
    Password is only saved locally and will not be seen when typing.
    Please enter your sudo password: " password1
	echo " "
	# Prompt for password verification
	read -r -s -p "Please re-enter your password to verify: " password2
	echo " "

	# Check if the passwords match
	if [ "$password1" = "$password2" ]; then
		export PASSWD=$password1
		echo "Password verified successfully."
		break
	else
		echo "Passwords do not match. Please enter the passwords again."
	fi
done

echo "Beginning Installation"

############################ DTC's MET & METPLUS ##################################################

###################################################################################################

if [ "$Ubuntu_64bit_Intel" = "1" ]; then

	echo $PASSWD | sudo -S sudo apt install git
	echo "MET INSTALLING"
	echo $PASSWD | sudo -S apt -y update
	echo $PASSWD | sudo -S apt -y upgrade

	# download the key to system keyring; this and the following echo command are
	# needed in order to install the Intel compilers
	wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB |
		gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg >/dev/null

	# add signed entry to apt sources and configure the APT client to use Intel repository:
	echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list

	# this update should get the Intel package info from the Intel repository
	echo $PASSWD | sudo -S apt -y update
	echo $PASSWD | sudo -S apt -y upgrade

	release_version=$(lsb_release -r -s)

	# Compare the release version
	if [ "$release_version" = "24.04" ]; then
		# Install Emacs without recommended packages
		echo $PASSWD | sudo -S apt install emacs --no-install-recommends -y
	else
		# Attempt to install Emacs if the release version is not 24.04
		echo "The release version is not 24.04, attempting to install Emacs."
		echo $PASSWD | sudo -S apt install emacs -y
	fi

	echo $PASSWD | sudo -S dnf -y install byacc bzip2 bzip2-devel cairo-devel cmake cpp curl curl-devel flex fontconfig fontconfig-devel gcc gcc-c++ gcc-gfortran git ksh libjpeg libjpeg-devel libstdc++ libstdc++-devel libX11 libX11-devel libXaw libXaw-devel libXext-devel libXmu libXmu-devel libXrender libXrender-devel libXt libXt-devel libxml2 libxml2-devel libgeotiff libgeotiff-devel libtiff libtiff-devel m4 nfs-utils perl 'perl(XML::LibXML)' pkgconfig pixman pixman-devel python3 python3-devel tcsh time unzip wget
	#
	# install the Intel compilers
	echo $PASSWD | sudo -S apt -y install intel-basekit
	echo $PASSWD | sudo -S apt -y install intel-hpckit
	echo $PASSWD | sudo -S apt -y install intel-oneapi-python
	/opt/intel/oneapi/intelpython/python3.12/bin/python3 -m pip install python-dateutil

	echo $PASSWD | sudo -S apt -y update

	# make sure some critical packages have been installed
	which cmake pkg-config make gcc g++ gfortran

	# add the Intel compiler file paths to various environment variables
	source /opt/intel/oneapi/setvars.sh --force

	# some of the libraries we install below need one or more of these variables
	export CC=icx
	export CXX=icpx
	export FC=ifx
	export F77=ifx
	export F90=ifx
	export MPIFC=mpiifx
	export MPIF77=mpiifx
	export MPIF90=mpiifx
	export MPICC=mpiicx
	export MPICXX=mpiicpx
	export CFLAGS="-fPIC -fPIE -O3 -Wno-implicit-function-declaration -Wno-incompatible-function-pointer-types -Wno-unused-command-line-argument"
	export FFLAGS="-m64"
	export FCFLAGS="-m64"
	export CXXFLAGS="-Wall -DHAVE_ISATTY"
	#########################

	#Downloading latest dateutil due to python3.8 running old version.
	pip3 install python-dateutil==2.8 --break-system-packages
	pip3 install python-dateutil

	mkdir $HOME/DTC
	export WRF_FOLDER=$HOME/DTC

	mkdir "${WRF_FOLDER}"/MET-$met_Version_number
	mkdir "${WRF_FOLDER}"/MET-$met_Version_number/Downloads
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

	#Downloading MET and untarring files
	#Note weblinks change often update as needed.
	cd "${WRF_FOLDER}"/MET-$met_Version_number/Downloads
	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.met-v$met_VERSION_number.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh "${WRF_FOLDER}"/MET-$met_Version_number
	LD_LIBRARY_PATH= tar -xvzf tar_files.met-v$met_VERSION_number.tgz -C "${WRF_FOLDER}"/MET-$met_Version_number
	cp v$met_Version_number.tar.gz "${WRF_FOLDER}"/MET-$met_Version_number/tar_files
	cd "${WRF_FOLDER}"/MET-$met_Version_number

	cd "${WRF_FOLDER}"/MET-$met_Version_number

	export PYTHON_VERSION=$(/opt/intel/oneapi/intelpython/latest/bin/python3 -V 2>&1 | awk '{print $2}')
	export PYTHON_VERSION_MAJOR_VERSION=$(echo "$PYTHON_VERSION" | awk -F. '{print $1}')
	export PYTHON_VERSION_MINOR_VERSION=$(echo "$PYTHON_VERSION" | awk -F. '{print $2}')
	export PYTHON_VERSION_COMBINED="$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION"

	echo "PYTHON_VERSION:               $PYTHON_VERSION"
	echo "PYTHON_VERSION_MAJOR_VERSION: $PYTHON_VERSION_MAJOR_VERSION"
	echo "PYTHON_VERSION_MINOR_VERSION: $PYTHON_VERSION_MINOR_VERSION"
	echo "PYTHON_VERSION_COMBINED:      $PYTHON_VERSION_COMBINED"

	# --- GCC/ICX version extraction ---
	export GCC_VERSION=$(icx -dumpversion)
	export GCC_VERSION_MAJOR_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $1}')
	export GCC_VERSION_MINOR_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $2}')
	export GCC_VERSION_SUB_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $3}' | sed 's/[^0-9]*//g')
	export GCC_VERSION_COMBINED="$GCC_VERSION_MAJOR_VERSION.$GCC_VERSION_MINOR_VERSION.$GCC_VERSION_SUB_VERSION"

	echo "GCC_VERSION:                  $GCC_VERSION"
	echo "GCC_VERSION_MAJOR_VERSION:    $GCC_VERSION_MAJOR_VERSION"
	echo "GCC_VERSION_MINOR_VERSION:    $GCC_VERSION_MINOR_VERSION"
	echo "GCC_VERSION_SUB_VERSION:      $GCC_VERSION_SUB_VERSION"
	echo "GCC_VERSION_COMBINED:         $GCC_VERSION_COMBINED"

	export CC=icx
	export CXX=icpx
	export FC=ifx
	export F77=ifx
	export F90=ifx
	export gcc_version=$GCC_VERSION
	export TEST_BASE="${WRF_FOLDER}"/MET-$met_Version_number
	export COMPILER=intel_$GCC_VERSION_COMBINED
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/opt/intel/oneapi/intelpython/python${PYTHON_VERSION_COMBINED}
	export MET_PYTHON_CC="-I ${MET_PYTHON}/include/python${PYTHON_VERSION_COMBINED}"
	export MET_PYTHON_LD="-L${MET_PYTHON}/lib/python${PYTHON_VERSION_COMBINED}/config-${PYTHON_VERSION_COMBINED}-x86_64-linux-gnu -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED} -lpthread -ldl -lutil -lm"
	export SET_D64BIT=FALSE

	export CPU_CORE=$(nproc) # number of available threads on system
	export CPU_6CORE="6"
	export CPU_QUARTER=$(($CPU_CORE / 4))                          #quarter of availble cores on system
	export CPU_QUARTER_EVEN=$(($CPU_QUARTER - ($CPU_QUARTER % 2))) #Forces CPU cores to even number to avoid partial core export. ie 7 cores would be 3.5 cores.

	if [ $CPU_CORE -le $CPU_6CORE ]; then #If statement for low core systems.  Forces computers to only use 1 core if there are 4 cores or less on the system.
		export CPU_QUARTER_EVEN="2"
	else
		export CPU_QUARTER_EVEN=$(($CPU_QUARTER - ($CPU_QUARTER % 2)))
	fi

	echo "##########################################"
	echo "Number of Threads being used $CPU_QUARTER_EVEN"
	echo "##########################################"

	echo " "

	export MAKE_ARGS="-j $CPU_QUARTER_EVEN"

	chmod 775 compile_MET_all.sh

	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

	export PATH="${WRF_FOLDER}"/MET-$met_Version_number/bin:$PATH #Add MET executables to path

	#Basic Package Management for Model Evaluation Tools (METplus)

	echo $PASSWD | sudo -S apt -y update
	echo $PASSWD | sudo -S apt -y upgrade

	#Directory Listings for Model Evaluation Tools (METplus

	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

	#Downloading METplus and untarring files

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
	LD_LIBRARY_PATH= tar -xvzf v$METPLUS_Version.tar.gz -C "${WRF_FOLDER}"

	# Insatlllation of Model Evaluation Tools Plus
	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = "${WRF_FOLDER}"/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper.tgz
	LD_LIBRARY_PATH= tar -xvzf sample_data-met_tool_wrapper.tgz -C "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data

	# Testing if installation of MET & METPlus was sucessfull
	# If you see in terminal "METplus has successfully finished running."
	# Then MET & METPLUS is sucessfully installed

	echo 'Testing MET & METPLUS Installation.'
	$WRF_FOLDER/METplus-$METPLUS_Version/ush/run_metplus.py -c $WRF_FOLDER/METplus-$METPLUS_Version/parm/use_cases/met_tool_wrapper/GridStat/GridStat.conf

	# Check if the previous command was successful
	if [ $? -eq 0 ]; then
		echo " "
		echo "MET and METPLUS successfully installed with GNU compilers."
		echo " "
		export PATH=$WRF_FOLDER/METplus-$METPLUS_Version/ush:$PATH
	else
		echo " "
		echo "Error: MET and METPLUS installation failed."
		echo " "
		# Handle the error case, e.g., exit the script or retry installation
		exit 1
	fi
fi

if [ "$Ubuntu_64bit_GNU" = "1" ]; then

	echo $PASSWD | sudo -S sudo apt install git
	echo "MET INSTALLING"
	export HOME=$(
		cd
		pwd
	)
	#Basic Package Management for Model Evaluation Tools (MET)

	#############################basic package managment############################
	echo $PASSWD | sudo -S apt -y update
	echo $PASSWD | sudo -S apt -y upgrade

	release_version=$(lsb_release -r -s)

	# Compare the release version
	if [ "$release_version" = "24.04" ]; then
		# Install Emacs without recommended packages
		echo $PASSWD | sudo -S apt install emacs --no-install-recommends -y
	else
		# Attempt to install Emacs if the release version is not 24.04
		echo "The release version is not 24.04, attempting to install Emacs."
		echo $PASSWD | sudo -S apt install emacs -y
	fi

	echo "$PASSWD" | sudo -S apt -y install bison build-essential byacc cmake csh curl default-jdk default-jre flex libfl-dev g++ gawk gcc gettext gfortran git ksh libcurl4-gnutls-dev libjpeg-dev libncurses6 libncursesw5-dev libpixman-1-dev libpng-dev libtool libxml2 libxml2-dev libxml-libxml-perl m4 make ncview pipenv pkg-config python3 python3-dev python3-pip python3-dateutil tcsh unzip xauth xorg time ghostscript less libbz2-dev libc6-dev libffi-dev libgdbm-dev libopenblas-dev libreadline-dev libssl-dev libtiff-dev libgeotiff-dev tk-dev vim wget

	#Downloading latest dateutil due to python3.8 running old version.
	echo $PASSWD | sudo -S apt -y install python3-dateutil

	mkdir $HOME/DTC
	export WRF_FOLDER=$HOME/DTC

	mkdir "${WRF_FOLDER}"/MET-$met_Version_number
	mkdir "${WRF_FOLDER}"/MET-$met_Version_number/Downloads
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

	#Downloading MET and untarring files
	#Note weblinks change often update as needed.
	cd "${WRF_FOLDER}"/MET-$met_Version_number/Downloads

	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.met-v$met_VERSION_number.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh "${WRF_FOLDER}"/MET-$met_Version_number
	LD_LIBRARY_PATH= tar -xvzf tar_files.met-v$met_VERSION_number.tgz -C "${WRF_FOLDER}"/MET-$met_Version_number
	cp v$met_Version_number.tar.gz "${WRF_FOLDER}"/MET-$met_Version_number/tar_files
	cd "${WRF_FOLDER}"/MET-$met_Version_number

	# Installation of Model Evaluation Tools
	export CC=gcc
	export CXX=g++
	export FC=gfortran
	export F77=gfortran
	export CFLAGS="-fPIC -fPIE -O3"

	cd "${WRF_FOLDER}"/MET-$met_Version_number
	export GCC_VERSION=$(gcc -dumpfullversion | awk '{print$1}')
	export GFORTRAN_VERSION=$(gfortran -dumpfullversion | awk '{print$1}')
	export GPLUSPLUS_VERSION=$(g++ -dumpfullversion | awk '{print$1}')

	export GCC_VERSION_MAJOR_VERSION=$(echo $GCC_VERSION | awk -F. '{print $1}')
	export GFORTRAN_VERSION_MAJOR_VERSION=$(echo $GFORTRAN_VERSION | awk -F. '{print $1}')
	export GPLUSPLUS_VERSION_MAJOR_VERSION=$(echo $GPLUSPLUS_VERSION | awk -F. '{print $1}')

	export version_10="10"

	export PYTHON_VERSION=$(/usr/bin/python3 -V 2>&1 | awk '{print $2}')
	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION

	echo "PYTHON_VERSION:               $PYTHON_VERSION"
	echo "PYTHON_VERSION_MAJOR_VERSION: $PYTHON_VERSION_MAJOR_VERSION"
	echo "PYTHON_VERSION_MINOR_VERSION: $PYTHON_VERSION_MINOR_VERSION"
	echo "PYTHON_VERSION_COMBINED:      $PYTHON_VERSION_COMBINED"

	# --- GCC/ version extraction ---
	export GCC_VERSION=$(gcc -dumpfullversion)
	export GCC_VERSION_MAJOR_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $1}')
	export GCC_VERSION_MINOR_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $2}')
	export GCC_VERSION_SUB_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $3}' | sed 's/[^0-9]*//g')
	export GCC_VERSION_COMBINED="$GCC_VERSION_MAJOR_VERSION.$GCC_VERSION_MINOR_VERSION.$GCC_VERSION_SUB_VERSION"

	echo "GCC_VERSION:                  $GCC_VERSION"
	echo "GCC_VERSION_MAJOR_VERSION:    $GCC_VERSION_MAJOR_VERSION"
	echo "GCC_VERSION_MINOR_VERSION:    $GCC_VERSION_MINOR_VERSION"
	echo "GCC_VERSION_SUB_VERSION:      $GCC_VERSION_SUB_VERSION"
	echo "GCC_VERSION_COMBINED:         $GCC_VERSION_COMBINED"

	export FC=/usr/bin/gfortran
	export F77=/usr/bin/gfortran
	export F90=/usr/bin/gfortran
	export gcc_version=$GCC_VERSION
	export TEST_BASE="${WRF_FOLDER}"/MET-$met_Version_number
	export COMPILER=gnu_$GCC_VERSION_COMBINED
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/usr
	export MET_PYTHON_CC="-I${MET_PYTHON}/include/python${PYTHON_VERSION_COMBINED}"
	export MET_PYTHON_LD="$(python3-config --ldflags) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"
	export SET_D64BIT=FALSE

	export CPU_CORE=$(nproc) # number of available threads on system
	export CPU_6CORE="6"
	export CPU_QUARTER=$(($CPU_CORE / 4))                          #quarter of availble cores on system
	export CPU_QUARTER_EVEN=$(($CPU_QUARTER - ($CPU_QUARTER % 2))) #Forces CPU cores to even number to avoid partial core export. ie 7 cores would be 3.5 cores.

	if [ $CPU_CORE -le $CPU_6CORE ]; then #If statement for low core systems.  Forces computers to only use 1 core if there are 4 cores or less on the system.
		export CPU_QUARTER_EVEN="2"
	else
		export CPU_QUARTER_EVEN=$(($CPU_QUARTER - ($CPU_QUARTER % 2)))
	fi

	echo "##########################################"
	echo "Number of Threads being used $CPU_QUARTER_EVEN"
	echo "##########################################"

	echo " "

	export MAKE_ARGS="-j $CPU_QUARTER_EVEN"

	chmod 775 compile_MET_all.sh

	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

	export PATH="${WRF_FOLDER}"/MET-$met_Version_number/bin:$PATH

	#basic Package Management for Model Evaluation Tools (METplus)

	echo $PASSWD | sudo -S apt -y update
	echo $PASSWD | sudo -S apt -y upgrade

	#Directory Listings for Model Evaluation Tools (METplus

	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

	#Downloading METplus and untarring files

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
	LD_LIBRARY_PATH= tar -xvzf v$METPLUS_Version.tar.gz -C "${WRF_FOLDER}"

	# Insatlllation of Model Evaluation Tools Plus
	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = "${WRF_FOLDER}"/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper.tgz
	LD_LIBRARY_PATH= tar -xvzf sample_data-met_tool_wrapper.tgz -C "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data

	# Testing if installation of MET & METPlus was sucessfull
	# If you see in terminal "METplus has successfully finished running."
	# Then MET & METPLUS is sucessfully installed

	echo 'Testing MET & METPLUS Installation.'
	$WRF_FOLDER/METplus-$METPLUS_Version/ush/run_metplus.py -c $WRF_FOLDER/METplus-$METPLUS_Version/parm/use_cases/met_tool_wrapper/GridStat/GridStat.conf

	# Check if the previous command was successful
	if [ $? -eq 0 ]; then
		echo " "
		echo "MET and METPLUS successfully installed with GNU compilers."
		echo " "
		export PATH=$WRF_FOLDER/METplus-$METPLUS_Version/ush:$PATH
	else
		echo " "
		echo "Error: MET and METPLUS installation failed."
		echo " "
		# Handle the error case, e.g., exit the script or retry installation
		exit 1
	fi
fi

if [ "$RHL_64bit_GNU" = "1" ]; then
	export HOME=$(
		cd
		pwd
	)

	echo $PASSWD | sudo -S sudo dnf install git

	#Basic Package Management for Model Evaluation Tools (MET)
	echo $PASSWD | sudo -S yum install epel-release -y
	echo $PASSWD | sudo -S yum install dnf -y
	echo $PASSWD | sudo -S dnf install epel-release -y
	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade
	echo $PASSWD | sudo -S dnf -y install byacc bzip2 bzip2-devel cairo-devel cmake cpp curl curl-devel flex fontconfig fontconfig-devel gcc gcc-c++ gcc-gfortran git ksh libjpeg libjpeg-devel libstdc++ libstdc++-devel libX11 libX11-devel libXaw libXaw-devel libXext-devel libXmu libXmu-devel libXrender libXrender-devel libXt libXt-devel libxml2 libxml2-devel libgeotiff libgeotiff-devel libtiff libtiff-devel m4 nfs-utils perl 'perl(XML::LibXML)' pkgconfig pixman pixman-devel python3 python3-devel tcsh time unzip wget
	echo $PASSWD | sudo -S dnf -y java-devel java
	echo $PASSWD | sudo -S dnf -y java-17-openjdk-devel java-17-openjdk
	echo $PASSWD | sudo -S dnf -y java-21-openjdk-devel java-21-openjdk
	echo $PASSWD | sudo -S dnf -y install python3-dateutil
	echo $PASSWD | sudo -S dnf -y groupinstall "Development Tools"
	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade
	echo " "

	mkdir $HOME/DTC
	export WRF_FOLDER=$HOME/DTC

	mkdir "${WRF_FOLDER}"/MET-$met_Version_number
	mkdir "${WRF_FOLDER}"/MET-$met_Version_number/Downloads
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

	#Downloading MET and untarring files
	#Note weblinks change often update as needed.
	cd "${WRF_FOLDER}"/MET-$met_Version_number/Downloads

	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.met-v$met_VERSION_number.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh "${WRF_FOLDER}"/MET-$met_Version_number
	LD_LIBRARY_PATH= tar -xvzf tar_files.met-v$met_VERSION_number.tgz -C "${WRF_FOLDER}"/MET-$met_Version_number
	cp v$met_Version_number.tar.gz "${WRF_FOLDER}"/MET-$met_Version_number/tar_files
	cd "${WRF_FOLDER}"/MET-$met_Version_number

	# Installation of Model Evaluation Tools

	cd "${WRF_FOLDER}"/MET-$met_Version_number

	export PYTHON_VERSION=$(/usr/bin/python3 -V 2>&1 | awk '{print $2}')
	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION

	echo "PYTHON_VERSION:               $PYTHON_VERSION"
	echo "PYTHON_VERSION_MAJOR_VERSION: $PYTHON_VERSION_MAJOR_VERSION"
	echo "PYTHON_VERSION_MINOR_VERSION: $PYTHON_VERSION_MINOR_VERSION"
	echo "PYTHON_VERSION_COMBINED:      $PYTHON_VERSION_COMBINED"

	# --- GCC/ version extraction ---
	export GCC_VERSION=$(gcc -dumpfullversion)
	export GCC_VERSION_MAJOR_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $1}')
	export GCC_VERSION_MINOR_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $2}')
	export GCC_VERSION_SUB_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $3}' | sed 's/[^0-9]*//g')
	export GCC_VERSION_COMBINED="$GCC_VERSION_MAJOR_VERSION.$GCC_VERSION_MINOR_VERSION.$GCC_VERSION_SUB_VERSION"

	echo "GCC_VERSION:                  $GCC_VERSION"
	echo "GCC_VERSION_MAJOR_VERSION:    $GCC_VERSION_MAJOR_VERSION"
	echo "GCC_VERSION_MINOR_VERSION:    $GCC_VERSION_MINOR_VERSION"
	echo "GCC_VERSION_SUB_VERSION:      $GCC_VERSION_SUB_VERSION"
	echo "GCC_VERSION_COMBINED:         $GCC_VERSION_COMBINED"

	export CC=gcc
	export CXX=g++
	export CFLAGS="-fPIC -fPIE -O3"
	export FC=gfortran
	export F77=gfortran
	export F90=gfortran
	export gcc_version=$GCC_VERSION
	export TEST_BASE="${WRF_FOLDER}"/MET-$met_Version_number
	export COMPILER=gnu_$GCC_VERSION_COMBINED
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/usr
	export MET_PYTHON_CC="-I${MET_PYTHON}/include/python${PYTHON_VERSION_COMBINED}"
	export MET_PYTHON_LD="$(python3-config --ldflags) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"
	export SET_D64BIT=FALSE

	echo "CC=$CC"
	echo "CXX=$CXX"
	echo "FC=$FC"
	echo "F77=$F77"
	echo "F90=$F90"
	echo "gcc_version=$gcc_version"
	echo "TEST_BASE=$TEST_BASE"
	echo "COMPILER=$COMPILER"
	echo "MET_SUBDIR=$MET_SUBDIR"
	echo "MET_TARBALL=$MET_TARBALL"
	echo "USE_MODULES=$USE_MODULES"
	echo "MET_PYTHON=$MET_PYTHON"
	echo "MET_PYTHON_CC=$MET_PYTHON_CC"
	echo "MET_PYTHON_LD=$MET_PYTHON_LD"
	echo "SET_D64BIT=$SET_D64BIT"

	export CPU_CORE=$(nproc) # number of available threads on system
	export CPU_6CORE="6"
	export CPU_QUARTER=$(($CPU_CORE / 4))                          #quarter of availble cores on system
	export CPU_QUARTER_EVEN=$(($CPU_QUARTER - ($CPU_QUARTER % 2))) #Forces CPU cores to even number to avoid partial core export. ie 7 cores would be 3.5 cores.

	if [ $CPU_CORE -le $CPU_6CORE ]; then #If statement for low core systems.  Forces computers to only use 1 core if there are 4 cores or less on the system.
		export CPU_QUARTER_EVEN="2"
	else
		export CPU_QUARTER_EVEN=$(($CPU_QUARTER - ($CPU_QUARTER % 2)))
	fi

	echo "##########################################"
	echo "Number of Threads being used $CPU_QUARTER_EVEN"
	echo "##########################################"

	echo " "

	export MAKE_ARGS="-j $CPU_QUARTER_EVEN"

	chmod 775 compile_MET_all.sh

	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

	export PATH="${WRF_FOLDER}"/MET-$met_Version_number/bin:$PATH

	#basic Package Management for Model Evaluation Tools (METplus)

	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade

	#Directory Listings for Model Evaluation Tools (METplus

	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

	#Downloading METplus and untarring files

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
	LD_LIBRARY_PATH= tar -xvzf v$METPLUS_Version.tar.gz -C "${WRF_FOLDER}"

	# Insatlllation of Model Evaluation Tools Plus
	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = "${WRF_FOLDER}"/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper.tgz
	LD_LIBRARY_PATH= tar -xvzf sample_data-met_tool_wrapper.tgz -C "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data

	# Testing if installation of MET & METPlus was sucessfull
	# If you see in terminal "METplus has successfully finished running."
	# Then MET & METPLUS is sucessfully installed

	echo 'Testing MET & METPLUS Installation.'
	$WRF_FOLDER/METplus-$METPLUS_Version/ush/run_metplus.py -c $WRF_FOLDER/METplus-$METPLUS_Version/parm/use_cases/met_tool_wrapper/GridStat/GridStat.conf

	# Check if the previous command was successful
	if [ $? -eq 0 ]; then
		echo " "
		echo "MET and METPLUS successfully installed with GNU compilers."
		echo " "
		export PATH=$WRF_FOLDER/METplus-$METPLUS_Version/ush:$PATH
	else
		echo " "
		echo "Error: MET and METPLUS installation failed."
		echo " "
		# Handle the error case, e.g., exit the script or retry installation
		exit 1
	fi
fi

if [ "$RHL_64bit_GNU" = "2" ]; then

	echo $PASSWD | sudo -S sudo dnf install git

	echo "MET INSTALLING"
	export HOME=$(
		cd
		pwd
	)

	#Basic Package Management for Model Evaluation Tools (MET)

	echo $PASSWD | sudo -S yum install epel-release -y
	echo $PASSWD | sudo -S yum install dnf -y
	echo $PASSWD | sudo -S dnf install epel-release -y
	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade
	echo $PASSWD | sudo -S dnf -y install byacc bzip2 bzip2-devel cairo-devel cmake cpp curl curl-devel flex fontconfig fontconfig-devel gcc gcc-c++ gcc-gfortran git ksh libjpeg libjpeg-devel libstdc++ libstdc++-devel libX11 libX11-devel libXaw libXaw-devel libXext-devel libXmu libXmu-devel libXrender libXrender-devel libXt libXt-devel libxml2 libxml2-devel libgeotiff libgeotiff-devel libtiff libtiff-devel m4 nfs-utils perl 'perl(XML::LibXML)' pkgconfig pixman pixman-devel python3 python3-devel tcsh time unzip wget
	echo $PASSWD | sudo -S dnf -y java-devel java
	echo $PASSWD | sudo -S dnf -y java-17-openjdk-devel java-17-openjdk
	echo $PASSWD | sudo -S dnf -y java-21-openjdk-devel java-21-openjdk
	echo $PASSWD | sudo -S dnf -y install python3-dateutil
	--break-system-packages
	echo $PASSWD | sudo -S dnf -y groupinstall "Development Tools"
	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade
	echo " "

	echo "old version of GNU detected"
	echo $PASSWD | sudo -S yum install RHL-release-scl -y
	echo $PASSWD | sudo -S yum clean all
	echo $PASSWD | sudo -S yum remove devtoolset-11*
	echo $PASSWD | sudo -S yum install devtoolset-11
	echo $PASSWD | sudo -S yum install devtoolset-11-\* -y
	source /opt/rh/devtoolset-11/enable
	gcc --version
	echo $PASSWD | sudo -S yum install rh-python38* -y
	source /opt/rh/rh-python38/enable
	python3 -V
	echo $PASSWD | sudo echo $PASSWD | sudo -S ./opt/rh/rh-python38/root/bin/pip3.8 install python-dateutil --break-system-packages

	mkdir $HOME/DTC
	export WRF_FOLDER=$HOME/DTC

	mkdir "${WRF_FOLDER}"/MET-$met_Version_number
	mkdir "${WRF_FOLDER}"/MET-$met_Version_number/Downloads
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

	#Downloading MET and untarring files
	#Note weblinks change often update as needed.
	cd "${WRF_FOLDER}"/MET-$met_Version_number/Downloads

	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.met-v$met_VERSION_number.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh "${WRF_FOLDER}"/MET-$met_Version_number
	LD_LIBRARY_PATH= tar -xvzf tar_files.met-v$met_VERSION_number.tgz -C "${WRF_FOLDER}"/MET-$met_Version_number
	cp v$met_Version_number.tar.gz "${WRF_FOLDER}"/MET-$met_Version_number/tar_files
	cd "${WRF_FOLDER}"/MET-$met_Version_number

	# Installation of Model Evaluation Tools

	cd "${WRF_FOLDER}"/MET-$met_Version_number

	export PYTHON_VERSION=$(/opt/rh/rh-python38/root/usr/bin/python3 -V 2>&1 | awk '{print $2}')
	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION

	echo "PYTHON_VERSION:               $PYTHON_VERSION"
	echo "PYTHON_VERSION_MAJOR_VERSION: $PYTHON_VERSION_MAJOR_VERSION"
	echo "PYTHON_VERSION_MINOR_VERSION: $PYTHON_VERSION_MINOR_VERSION"
	echo "PYTHON_VERSION_COMBINED:      $PYTHON_VERSION_COMBINED"

	# --- GCC/ version extraction ---
	export GCC_VERSION=$(gcc -dumpfullversion)
	export GCC_VERSION_MAJOR_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $1}')
	export GCC_VERSION_MINOR_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $2}')
	export GCC_VERSION_SUB_VERSION=$(echo "$GCC_VERSION" | awk -F. '{print $3}' | sed 's/[^0-9]*//g')
	export GCC_VERSION_COMBINED="$GCC_VERSION_MAJOR_VERSION.$GCC_VERSION_MINOR_VERSION.$GCC_VERSION_SUB_VERSION"

	echo "GCC_VERSION:                  $GCC_VERSION"
	echo "GCC_VERSION_MAJOR_VERSION:    $GCC_VERSION_MAJOR_VERSION"
	echo "GCC_VERSION_MINOR_VERSION:    $GCC_VERSION_MINOR_VERSION"
	echo "GCC_VERSION_SUB_VERSION:      $GCC_VERSION_SUB_VERSION"
	echo "GCC_VERSION_COMBINED:         $GCC_VERSION_COMBINED"

	export CC=gcc
	export CXX=g++
	export CFLAGS="-fPIC -fPIE -O3"
	export FC=gfortran
	export F77=gfortran
	export F90=gfortran
	export gcc_version=$GCC_VERSION
	export TEST_BASE="${WRF_FOLDER}"/MET-$met_Version_number
	export COMPILER=gnu_$GCC_VERSION_COMBINED
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/opt/rh/rh-python38/root/usr/
	export MET_PYTHON_CC="-I${MET_PYTHON}/include/python${PYTHON_VERSION_COMBINED}"
	export MET_PYTHON_LD="$(python3-config --ldflags) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"
	export SET_D64BIT=FALSE

	export CPU_CORE=$(nproc) # number of available threads on system
	export CPU_6CORE="6"
	export CPU_QUARTER=$(($CPU_CORE / 4))                          #quarter of availble cores on system
	export CPU_QUARTER_EVEN=$(($CPU_QUARTER - ($CPU_QUARTER % 2))) #Forces CPU cores to even number to avoid partial core export. ie 7 cores would be 3.5 cores.

	if [ $CPU_CORE -le $CPU_6CORE ]; then #If statement for low core systems.  Forces computers to only use 1 core if there are 4 cores or less on the system.
		export CPU_QUARTER_EVEN="2"
	else
		export CPU_QUARTER_EVEN=$(($CPU_QUARTER - ($CPU_QUARTER % 2)))
	fi

	echo "##########################################"
	echo "Number of Threads being used $CPU_QUARTER_EVEN"
	echo "##########################################"

	echo " "

	export MAKE_ARGS="-j $CPU_QUARTER_EVEN"

	chmod 775 compile_MET_all.sh

	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

	export PATH="${WRF_FOLDER}"/MET-$met_Version_number/bin:$PATH

	#basic Package Management for Model Evaluation Tools (METplus)

	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade

	#Directory Listings for Model Evaluation Tools (METplus

	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

	#Downloading METplus and untarring files

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
	LD_LIBRARY_PATH= tar -xvzf v$METPLUS_Version.tar.gz -C "${WRF_FOLDER}"

	# Insatlllation of Model Evaluation Tools Plus
	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = "${WRF_FOLDER}"/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper.tgz
	LD_LIBRARY_PATH= tar -xvzf sample_data-met_tool_wrapper.tgz -C "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data

	# Testing if installation of MET & METPlus was sucessfull
	# If you see in terminal "METplus has successfully finished running."
	# Then MET & METPLUS is sucessfully installed

	echo 'Testing MET & METPLUS Installation.'
	$WRF_FOLDER/METplus-$METPLUS_Version/ush/run_metplus.py -c $WRF_FOLDER/METplus-$METPLUS_Version/parm/use_cases/met_tool_wrapper/GridStat/GridStat.conf

	# Check if the previous command was successful
	if [ $? -eq 0 ]; then
		echo " "
		echo "MET and METPLUS successfully installed with GNU compilers."
		echo " "
		export PATH=$WRF_FOLDER/METplus-$METPLUS_Version/ush:$PATH
	else
		echo " "
		echo "Error: MET and METPLUS installation failed."
		echo " "
		# Handle the error case, e.g., exit the script or retry installation
		exit 1
	fi
fi

if [ "$RHL_64bit_Intel" = "1"]; then
	#############################basic package managment############################
	echo $PASSWD | sudo -S yum install epel-release -y
	echo $PASSWD | sudo -S yum install dnf -y
	echo $PASSWD | sudo -S dnf install epel-release -y
	echo $PASSWD | sudo -S dnf install dnf -y
	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade

	#############################basic package managment############################
	echo $PASSWD | sudo -S yum install epel-release -y
	echo $PASSWD | sudo -S yum install dnf -y
	echo $PASSWD | sudo -S dnf install epel-release -y
	echo $PASSWD | sudo -S dnf install dnf -y
	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade
	echo $PASSWD | sudo -S dnf -y install -y automake bison cmake curl flex gcc-gfortran ghostscript git less bzip2-devel glibc-devel libffi-devel libcurl-devel libjpeg-turbo-devel ncurses-devel pixman-devel readline-devel libtiff-devel m4 tk-devel unzip vim wget make gcc gcc-c++ redhat-rpm-config
	echo $PASSWD | sudo -S dnf -y install python3-dateutil
	echo $PASSWD | sudo -S dnf -y groupinstall "Development Tools"

	# download the key to system keyring; this and the following echo command are
	# needed in order to install the Intel compilers

	echo $PASSWD | sudo bash -c 'printf "[oneAPI]\nname=Intel® oneAPI repository\nbaseurl=https://yum.repos.intel.com/oneapi\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB\n" > /etc/yum.repos.d/oneAPI.repo'

	echo $PASSWD | sudo -S mv /tmp/oneAPI.repo /etc/yum.repos.d

	# install the Intel compilersls -y
	echo $PASSWD | sudo -S dnf install intel-oneapi-base-toolkit -y
	echo $PASSWD | sudo -S dnf install intel-oneapi-hpc-toolkit -y
	echo $PASSWD | sudo -S dnf install intel-oneapi-python -y
	/opt/intel/oneapi/intelpython/python3.12/bin/python3 -m pip install python-dateutil
	echo $PASSWD | sudo -S dnf install intel-cpp-essentials -y

	echo $PASSWD | sudo -S dnf update
	echo $PASSWD | sudo -S dnf -y install cmake pkgconfig
	echo $PASSWD | sudo -S dnf groupinstall "Development Tools" -y

	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade

	# add the Intel compiler file paths to various environment variables
	source /opt/intel/oneapi/setvars.sh --force

	echo $PASSWD | sudo python3 -m pip install python-dateutil

	export WRF_FOLDER="$HOME/DTC_Intel"

	mkdir $WRF_FOLDER

	mkdir "${WRF_FOLDER}"/MET-$met_Version_number
	mkdir "${WRF_FOLDER}"/MET-$met_Version_number/Downloads
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

	#Downloading MET and untarring files
	#Note weblinks change often update as needed.
	cd "${WRF_FOLDER}"/MET-$met_Version_number/Downloads

	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.met-v$met_VERSION_number.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh "${WRF_FOLDER}"/MET-$met_Version_number
	LD_LIBRARY_PATH= tar -xvzf tar_files.met-v$met_VERSION_number.tgz -C "${WRF_FOLDER}"/MET-$met_Version_number
	cp v$met_Version_number.tar.gz "${WRF_FOLDER}"/MET-$met_Version_number/tar_files
	cd "${WRF_FOLDER}"/MET-$met_Version_number

	# Installation of Model Evaluation Tools

	cd "${WRF_FOLDER}"/MET-$met_Version_number

	export PYTHON_VERSION=$(/opt/intel/oneapi/intelpython/latest/bin/python3 -V 2>&1 | awk '{print $2}')
	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION
	echo "PYTHON_VERSION_MAJOR_VERSION: $PYTHON_VERSION_MAJOR_VERSION"
	echo "PYTHON_VERSION_MINOR_VERSION: $PYTHON_VERSION_MINOR_VERSION"
	echo "PYTHON_VERSION_COMBINED: $PYTHON_VERSION_COMBINED"

	export GCC_VERSION=$(icx -dumpversion)
	export GCC_VERSION_MAJOR_VERSION=$(echo $GCC_VERSION | awk -F. '{print $1}')
	export GCC_VERSION_MINOR_VERSION=$(echo $GCC_VERSION | awk -F. '{print $2}')
	export GCC_VERSION_SUB_VERSION=$(echo $GCC_VERSION | awk -F. '{print $3}' | sed 's/[^0-9]*//g')
	export GCC_VERSION_COMBINED=$GCC_VERSION_MAJOR_VERSION.$GCC_VERSION_MINOR_VERSION.$GCC_VERSION_SUB_VERSION

	echo "GCC_VERSION:                  $GCC_VERSION"
	echo "GCC_VERSION_MAJOR_VERSION:    $GCC_VERSION_MAJOR_VERSION"
	echo "GCC_VERSION_MINOR_VERSION:    $GCC_VERSION_MINOR_VERSION"
	echo "GCC_VERSION_SUB_VERSION:      $GCC_VERSION_SUB_VERSION"
	echo "GCC_VERSION_COMBINED:         $GCC_VERSION_COMBINED"

	export CC=icx
	export CXX=icpx
	export CFLAGS="-fPIC -fPIE -O3"
	export FC=ifx
	export F77=ifx
	export F90=ifx
	export gcc_version=$GCC_VERSION
	export TEST_BASE="${WRF_FOLDER}"/MET-$met_Version_number
	export COMPILER=intel_$GCC_VERSION_COMBINED
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/opt/intel/oneapi/intelpython/python${PYTHON_VERSION_COMBINED}
	export MET_PYTHON_CC="-I ${MET_PYTHON}/include/python${PYTHON_VERSION_COMBINED}"
	export MET_PYTHON_LD="-L${MET_PYTHON}/lib/python${PYTHON_VERSION_COMBINED}/config-${PYTHON_VERSION_COMBINED}-x86_64-linux-gnu -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED} -lpthread -ldl -lutil -lm"
	export SET_D64BIT=FALSE
	export CXXFLAGS="-Wall -DHAVE_ISATTY"

	export CPU_CORE=$(nproc) # number of available threads on system
	export CPU_6CORE="6"
	export CPU_QUARTER=$(($CPU_CORE / 4))                          #quarter of availble cores on system
	export CPU_QUARTER_EVEN=$(($CPU_QUARTER - ($CPU_QUARTER % 2))) #Forces CPU cores to even number to avoid partial core export. ie 7 cores would be 3.5 cores.

	if [ $CPU_CORE -le $CPU_6CORE ]; then #If statement for low core systems.  Forces computers to only use 1 core if there are 4 cores or less on the system.
		export CPU_QUARTER_EVEN="2"
	else
		export CPU_QUARTER_EVEN=$(($CPU_QUARTER - ($CPU_QUARTER % 2)))
	fi

	echo "##########################################"
	echo "Number of Threads being used $CPU_QUARTER_EVEN"
	echo "##########################################"

	echo " "

	export MAKE_ARGS="-j $CPU_QUARTER_EVEN"

	chmod 775 compile_MET_all.sh

	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

	export PATH="${WRF_FOLDER}"/MET-$met_Version_number/bin:$PATH #Add MET executables to path

	#Basic Package Management for Model Evaluation Tools (METplus)

	echo $PASSWD | sudo -S apt -y update
	echo $PASSWD | sudo -S apt -y upgrade

	#Directory Listings for Model Evaluation Tools (METplus

	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output
	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

	#Downloading METplus and untarring files

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
	LD_LIBRARY_PATH= tar -xvzf v$METPLUS_Version.tar.gz -C "${WRF_FOLDER}"

	# Insatlllation of Model Evaluation Tools Plus
	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = "${WRF_FOLDER}"/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper.tgz
	LD_LIBRARY_PATH= tar -xvzf sample_data-met_tool_wrapper.tgz -C "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data

	# Testing if installation of MET & METPlus was sucessfull
	# If you see in terminal "METplus has successfully finished running."
	# Then MET & METPLUS is sucessfully installed

	echo 'Testing MET & METPLUS Installation.'
	$WRF_FOLDER/METplus-$METPLUS_Version/ush/run_metplus.py -c $WRF_FOLDER/METplus-$METPLUS_Version/parm/use_cases/met_tool_wrapper/GridStat/GridStat.conf

	# Check if the previous command was successful
	if [ $? -eq 0 ]; then
		echo " "
		echo "MET and METPLUS successfully installed with Intel compilers."
		echo " "
		export PATH=$WRF_FOLDER/METplus-$METPLUS_Version/ush:$PATH
	else
		echo " "
		echo "Error: MET and METPLUS installation failed."
		echo " "
		# Handle the error case, e.g., exit the script or retry installation
		exit 1
	fi

fi

#####################################BASH Script Finished##############################

end=$(date)
END=$(date +"%s")
DIFF=$(($END - $START))
echo "Install Start Time: ${start}"
echo "Install End Time: ${end}"
echo "Install Duration: $(($DIFF / 3600)) hours $((($DIFF % 3600) / 60)) minutes $(($DIFF % 60)) seconds"
