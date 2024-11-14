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
export METPLUS_Version=5.1.0
export met_Version_number=11.1.1
export met_VERSION_number=11.1
export METPLUS_DATA=5.1

# Capture the start time for logging or performance measurement
start=$(date)
START=$(date +"%s")

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

########## CentOS and Linux Distribution Detection #############
# More accurate Linux distribution detection using /etc/os-release
#################################################################
if [ "$SYSTEMOS" = "Linux" ]; then
	if [ -f /etc/os-release ]; then
		# Extract the distribution name and version from /etc/os-release
		export DISTRO_NAME=$(grep -w "NAME" /etc/os-release | cut -d'=' -f2 | tr -d '"')
		export DISTRO_VERSION=$(grep -w "VERSION_ID" /etc/os-release | cut -d'=' -f2 | tr -d '"')

		echo "Operating system detected: $DISTRO_NAME, Version: $DISTRO_VERSION"

		# Check if the system is CentOS
		if grep -q "CentOS" /etc/os-release; then
			export SYSTEMOS="CentOS"
		fi
	else
		echo "Unable to detect the Linux distribution version."
	fi
fi

# Print the final detected OS
echo "Final operating system detected: $SYSTEMOS"

############################### Intel or GNU Compiler Option #############

# Only proceed with CentOS-specific logic if the system is CentOS
if [ "$SYSTEMOS" = "CentOS" ]; then
	# Check for 32-bit CentOS system
	if [ "$SYSTEMBIT" = "32" ]; then
		echo "Your system is not compatible with this script."
		exit
	fi

	# Check for 64-bit CentOS system
	if [ "$SYSTEMBIT" = "64" ]; then
		echo "Your system is a 64-bit version of CentOS Linux Kernel."
		echo ""
		echo "Intel compilers are not compatible with this script."
		echo ""

		# Check if Centos_64bit_GNU environment variable is set
		if [ -v Centos_64bit_GNU ]; then
			echo "The environment variable Centos_64bit_GNU is already set."
		else
			echo "The environment variable Centos_64bit_GNU is not set."
			echo "Setting compiler to GNU."
			export Centos_64bit_GNU=1

			# Check GNU version
			if [ "$(gcc -dumpversion 2>&1 | awk '{print $1}')" -lt 9 ]; then
				export Centos_64bit_GNU=2
				echo "OLD GNU FILES FOUND."
			fi
		fi
	fi
fi

# Check for 64-bit Linux system (Debian/Ubuntu)
if [ "$SYSTEMBIT" = "64" ] && [ "$SYSTEMOS" = "Linux" ]; then
	echo "Your system is a 64-bit version of Debian Linux Kernel."
	echo ""

	# Check if Ubuntu_64bit_Intel or Ubuntu_64bit_GNU environment variables are set
	if [ -v "$Ubuntu_64bit_Intel" ] || [ -v "$Ubuntu_64bit_GNU" ]; then
		echo "The environment variable Ubuntu_64bit_Intel/GNU is already set."
	else
		echo "The environment variable Ubuntu_64bit_Intel/GNU is not set."
		Intel_MESSAGE="\e[91m(Intel Compilers are NOT available due to Intel LLVM Upgrade. Please Select GNU)\e[0m"
		echo -e "$Intel_MESSAGE"

		# Prompt user to select a compiler (Intel or GNU)
		while read -r -p "Which compiler do you want to use?
            - Intel
            - GNU
            Please answer Intel or GNU and press enter (case-sensitive): " yn; do
			case $yn in
			Intel)
				echo ""
				echo "Intel is selected for installation."
				export Ubuntu_64bit_Intel=1
				break
				;;
			GNU)
				echo "--------------------------------------------------"
				echo ""
				echo "GNU is selected for installation."
				export Ubuntu_64bit_GNU=1
				break
				;;
			*)
				echo ""
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
	echo ""
	echo "Intel compilers are not compatible with this script."
	echo "Setting compiler to GNU..."

	# Check if macos_64bit_GNU environment variable is set
	if [ -v macos_64bit_GNU ]; then
		echo "The environment variable macos_64bit_GNU is already set."
	else
		echo "Setting environment variable macos_64bit_GNU."
		export macos_64bit_GNU=1

		# Ensure Xcode Command Line Tools are installed
		if ! xcode-select --print-path &>/dev/null; then
			echo "Installing Xcode Command Line Tools..."
			xcode-select --install
		fi

		# Install Homebrew for Intel Macs in /usr/local
		echo "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		echo 'eval "$(/usr/local/bin/brew shellenv)"' >>~/.profile
		eval "$(/usr/local/bin/brew shellenv)"

		chsh -s /bin/bash
	fi
fi

# Check for 64-bit ARM-based MacOS system (M1, M2 chips)
if [ "$SYSTEMBIT" = "64" ] && [ "$SYSTEMOS" = "MacOS" ] && [ "$MAC_CHIP" = "ARM" ]; then
	echo "Your system is a 64-bit version of macOS with an ARM chip (M1/M2)."
	echo ""
	echo "Intel compilers are not compatible with this script."
	echo "Setting compiler to GNU..."

	# Check if macos_64bit_GNU environment variable is set
	if [ -v macos_64bit_GNU ]; then
		echo "The environment variable macos_64bit_GNU is already set."
	else
		echo "Setting environment variable macos_64bit_GNU."
		export macos_64bit_GNU=1

		# Ensure Xcode Command Line Tools are installed
		if ! xcode-select --print-path &>/dev/null; then
			echo "Installing Xcode Command Line Tools..."
			xcode-select --install
		fi

		# Install Homebrew for ARM Macs in /opt/homebrew
		echo "Installing Homebrew..."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

		echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.profile
		eval "$(/opt/homebrew/bin/brew shellenv)"

		chsh -s /bin/bash
	fi
fi

############################# Enter sudo users information #############################
echo "--------------------------------------------------"
if [[ -n "$PASSWD" ]]; then
	echo "Using existing password: $PASSWD"
	echo "--------------------------------------------------"
else
	while true; do
		echo -e "\nPassword is only saved locally and will not be seen when typing."
		# Prompt for the initial password
		read -r -s -p "Please enter your sudo password: " password1
		echo -e "\nPlease re-enter your password to verify:"
		# Prompt for password verification
		read -r -s password2

		# Check if the passwords match
		if [[ "$password1" == "$password2" ]]; then
			export PASSWD=$password1
			echo -e "\n--------------------------------------------------"
			echo "Password verified successfully."
			break
		else
			echo -e "\n--------------------------------------------------"
			echo "Passwords do not match. Please enter the passwords again."
			echo "--------------------------------------------------"
		fi
	done
	echo -e "\nBeginning Installation\n"
fi

############################ DTC's MET & METPLUS ##################################################

###################################################################################################

# if [ "$Ubuntu_64bit_Intel" = "1" ] ; then

# 	echo $PASSWD | sudo -S sudo apt install git
# 	echo "MET INSTALLING"
# 	echo $PASSWD | sudo -S apt -y update
# 	echo $PASSWD | sudo -S apt -y upgrade

# 	# download the key to system keyring; this and the following echo command are
# 	# needed in order to install the Intel compilers
# 	wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB |
# 		gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg >/dev/null

# 	# add signed entry to apt sources and configure the APT client to use Intel repository:
# 	echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list

# 	# this update should get the Intel package info from the Intel repository
# 	echo $PASSWD | sudo -S apt -y update
# 	echo $PASSWD | sudo -S apt -y upgrade
# 	echo $PASSWD | sudo -S apt -y install autoconf automake bison build-essential byacc cmake csh curl default-jdk default-jre emacs --no-install-recommends flex g++ gawk gcc gfortran git ksh libcurl4-openssl-dev libjpeg-dev libncurses6 libpixman-1-dev libpng-dev libtool libxml2 libxml2-dev m4 make  ncview okular openbox pipenv pkg-config python3 python3-dev python3-pip tcsh unzip xauth xorg time

# 	# install the Intel compilers
# 	echo $PASSWD | sudo -S apt -y install intel-basekit
# 	echo $PASSWD | sudo -S apt -y install intel-hpckit
# 	echo $PASSWD | sudo -S apt -y install intel-oneapi-python

# 	echo $PASSWD | sudo -S apt -y update

# 	# make sure some critical packages have been installed
# 	which cmake pkg-config make gcc g++ gfortran

# 	# add the Intel compiler file paths to various environment variables
# 	source /opt/intel/oneapi/setvars.sh --force

# 	# some of the libraries we install below need one or more of these variables
#  	export CC=icx
# 	export CXX=icpx
# 	export FC=ifx
# 	export F77=ifx
# 	export F90=ifx
# 	export MPIFC=mpiifx
# 	export MPIF77=mpiifx
# 	export MPIF90=mpiifx
# 	export MPICC=mpiicx
# 	export MPICXX=mpiicpc
# 	export CFLAGS="-fPIC -fPIE -O3 -Wno-implicit-function-declaration -Wno-implicit-int -Wno-incompatible-function-pointer-types -Wno-unused-command-line-argument -Wno-deprecated-declarations -Wno-implicit-int"
# 	export FFLAGS="-m64"
# 	export FCFLAGS="-m64"
# 	#########################

# 	#Downloading latest dateutil due to python3.8 running old version.
# 	pip3 install python-dateutil==2.8
# 	pip3 install python-dateutil

# 	mkdir $HOME/DTC
#   export WRF_FOLDER=$HOME/DTC


# 	mkdir "${WRF_FOLDER}"/MET-$met_Version_number
# 	mkdir "${WRF_FOLDER}"/MET-$met_Version_number/Downloads
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

# 	#Downloading MET and untarring files
# 	#Note weblinks change often update as needed.
# 	cd "${WRF_FOLDER}"/MET-$met_Version_number/Downloads
# 	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

# 	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

# 	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

# 	cp compile_MET_all.sh "${WRF_FOLDER}"/MET-$met_Version_number
# 	tar -xvzf tar_files.tgz -C "${WRF_FOLDER}"/MET-$met_Version_number
# 	cp v$met_Version_number.tar.gz "${WRF_FOLDER}"/MET-$met_Version_number/tar_files
# 	cd "${WRF_FOLDER}"/MET-$met_Version_number


# 	export PYTHON_VERSION=$(/opt/intel/oneapi/intelpython/latest/bin/python3 -V 2>&1 | awk '{print $2}')
# 	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
# 	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
# 	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION

#   export CC=icx
# 	export CXX=icpx
# 	export FC=ifx
# 	export F77=ifx
# 	export F90=ifx
# 	export gcc_version=$(icx -dumpversion)
# 	export TEST_BASE="${WRF_FOLDER}"/MET-$met_Version_number
# 	export COMPILER=intel_$gcc_version
# 	export MET_SUBDIR=${TEST_BASE}
# 	export MET_TARBALL=v$met_Version_number.tar.gz
# 	export USE_MODULES=FALSE
# 	export MET_PYTHON=/opt/intel/oneapi/intelpython/python${PYTHON_VERSION_COMBINED}
# 	export MET_PYTHON_CC="-I ${MET_PYTHON}/include/python${PYTHON_VERSION_COMBINED}"
# 	export MET_PYTHON_LD="$(python3-config --ldflags --embed) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"
# 	export SET_D64BIT=FALSE

# 	echo "CC=$CC"
# 	echo "CXX=$CXX"
# 	echo "FC=$FC"
# 	echo "F77=$F77"
# 	echo "F90=$F90"
# 	echo "gcc_version=$gcc_version"
# 	echo "TEST_BASE=$TEST_BASE"
# 	echo "COMPILER=$COMPILER"
# 	echo "MET_SUBDIR=$MET_SUBDIR"
# 	echo "MET_TARBALL=$MET_TARBALL"
# 	echo "USE_MODULES=$USE_MODULES"
# 	echo "MET_PYTHON=$MET_PYTHON"
# 	echo "MET_PYTHON_CC=$MET_PYTHON_CC"
# 	echo "MET_PYTHON_LD=$MET_PYTHON_LD"
# 	echo "SET_D64BIT=$SET_D64BIT"

# 	export MAKE_ARGS="-j 4"


# 	chmod 775 compile_MET_all.sh

# 	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

# 	export PATH="${WRF_FOLDER}"/MET-$met_Version_number/bin:$PATH #Add MET executables to path

# 	#Basic Package Management for Model Evaluation Tools (METplus)

# 	echo $PASSWD | sudo -S apt -y update
# 	echo $PASSWD | sudo -S apt -y upgrade

# 	#Directory Listings for Model Evaluation Tools (METplus

# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

# 	#Downloading METplus and untarring files

# 	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
# 	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
# 	tar -xvzf v$METPLUS_Version.tar.gz -C "${WRF_FOLDER}"

# 	# Insatlllation of Model Evaluation Tools Plus
# 	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/metplus_config

# 	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = "${WRF_FOLDER}"/MET-$met_Version_number|" defaults.conf
# 	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
# 	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output|" defaults.conf

# 	# Downloading Sample Data

# 	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
# 	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
# 	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data

# 	# Testing if installation of MET & METPlus was sucessfull
# 	# If you see in terminal "METplus has successfully finished running."
# 	# Then MET & METPLUS is sucessfully installed

# 	echo 'Testing MET & METPLUS Installation.'
# 	"${WRF_FOLDER}"/METplus-$METPLUS_Version/ush/run_metplus.py -c "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/use_cases/met_tool_wrapper/GridStat/GridStat.conf

# 	# Check if the previous command was successful
# 	if [ $? -eq 0 ]; then
# 			echo " "
# 			echo "MET and METPLUS successfully installed with GNU compilers."
# 			echo " "
# 			export PATH="${WRF_FOLDER}"/METplus-$METPLUS_Version/ush:$PATH
# 	else
# 			echo " "
# 			echo "Error: MET and METPLUS installation failed."
# 			echo " "
# 			# Handle the error case, e.g., exit the script or retry installation
# 			exit 1
# 	fi
# fi

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
	echo $PASSWD | sudo -S apt -y install autoconf automake bison build-essential byacc cmake csh curl default-jdk default-jre emacs --no-install-recommends flex g++ gawk gcc gfortran git ksh libcurl4-openssl-dev libjpeg-dev libncurses6 libpixman-1-dev libpng-dev libtool libxml2 libxml2-dev m4 make ncview okular openbox pipenv pkg-config python3 python3-dev python3-pip tcsh unzip xauth xorg time

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

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh "${WRF_FOLDER}"/MET-$met_Version_number
	tar -xvzf tar_files.tgz -C "${WRF_FOLDER}"/MET-$met_Version_number
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

	export FC=/usr/bin/gfortran
	export F77=/usr/bin/gfortran
	export F90=/usr/bin/gfortran
	export gcc_version=$(gcc -dumpfullversion)
	export TEST_BASE="${WRF_FOLDER}"/MET-$met_Version_number
	export COMPILER=gnu_$gcc_version
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

	export MAKE_ARGS="-j 4"

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
	tar -xvzf v$METPLUS_Version.tar.gz -C "${WRF_FOLDER}"

	# Insatlllation of Model Evaluation Tools Plus
	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = "${WRF_FOLDER}"/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data

	# Testing if installation of MET & METPlus was sucessfull
	# If you see in terminal "METplus has successfully finished running."
	# Then MET & METPLUS is sucessfully installed

	echo 'Testing MET & METPLUS Installation.'
	"${WRF_FOLDER}"/METplus-$METPLUS_Version/ush/run_metplus.py -c "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/use_cases/met_tool_wrapper/GridStat/GridStat.conf

	# Check if the previous command was successful
	if [ $? -eq 0 ]; then
		echo " "
		echo "MET and METPLUS successfully installed with GNU compilers."
		echo " "
		export PATH="${WRF_FOLDER}"/METplus-$METPLUS_Version/ush:$PATH
	else
		echo " "
		echo "Error: MET and METPLUS installation failed."
		echo " "
		# Handle the error case, e.g., exit the script or retry installation
		exit 1
	fi
fi

if [ "$Centos_64bit_GNU" = "1" ]; then
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
	echo $PASSWD | sudo -S dnf -y install autoconf automake bzip2 bzip2-devel byacc cairo-devel cmake cpp curl curl-devel flex flex-devel fontconfig-devel fontconfig-devel.x86_64 gcc gcc-c++ gcc-gfortran git java-11-openjdk java-11-openjdk-devel ksh libX11-devel libX11-devel.x86_64 libXaw libXaw-devel libXext-devel libXext-devel.x86_64 libXmu-devel libXrender-devel libXrender-devel.x86_64 libstdc++ libstdc++-devel libstdc++-static libxml2 libxml2-devel m4 .x86_64 nfs-utils okular perl pkgconfig pixman-devel python3 python3-devel tcsh time unzip wget
	echo $PASSWD | sudo -S apt -y install python3-dateutil
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

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh "${WRF_FOLDER}"/MET-$met_Version_number
	tar -xvzf tar_files.tgz -C "${WRF_FOLDER}"/MET-$met_Version_number
	cp v$met_Version_number.tar.gz "${WRF_FOLDER}"/MET-$met_Version_number/tar_files
	cd "${WRF_FOLDER}"/MET-$met_Version_number

	# Installation of Model Evaluation Tools

	cd "${WRF_FOLDER}"/MET-$met_Version_number

	export PYTHON_VERSION=$(/usr/bin/python3 -V 2>&1 | awk '{print $2}')
	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION

	export CC=gcc
	export CXX=g++
	export CFLAGS="-fPIC -fPIE -O3"
	export FC=gfortran
	export F77=gfortran
	export F90=gfortran
	export gcc_version=$(gcc -dumpfullversion)
	export TEST_BASE="${WRF_FOLDER}"/MET-$met_Version_number
	export COMPILER=gnu_$gcc_version
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

	export MAKE_ARGS="-j 4"

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
	tar -xvzf v$METPLUS_Version.tar.gz -C "${WRF_FOLDER}"

	# Insatlllation of Model Evaluation Tools Plus
	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = "${WRF_FOLDER}"/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data

	# Testing if installation of MET & METPlus was sucessfull
	# If you see in terminal "METplus has successfully finished running."
	# Then MET & METPLUS is sucessfully installed

	echo 'Testing MET & METPLUS Installation.'
	"${WRF_FOLDER}"/METplus-$METPLUS_Version/ush/run_metplus.py -c "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/use_cases/met_tool_wrapper/GridStat/GridStat.conf

	# Check if the previous command was successful
	if [ $? -eq 0 ]; then
		echo " "
		echo "MET and METPLUS successfully installed with GNU compilers."
		echo " "
		export PATH="${WRF_FOLDER}"/METplus-$METPLUS_Version/ush:$PATH
	else
		echo " "
		echo "Error: MET and METPLUS installation failed."
		echo " "
		# Handle the error case, e.g., exit the script or retry installation
		exit 1
	fi
fi

if [ "$Centos_64bit_GNU" = "2" ]; then

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
	echo $PASSWD | sudo -S dnf -y install autoconf automake bzip2 bzip2-devel byacc cairo-devel cmake cpp curl curl-devel flex flex-devel fontconfig-devel fontconfig-devel.x86_64 gcc gcc-c++ gcc-gfortran git java-11-openjdk java-11-openjdk-devel ksh libX11-devel libX11-devel.x86_64 libXaw libXaw-devel libXext-devel libXext-devel.x86_64 libXmu-devel libXrender-devel libXrender-devel.x86_64 libstdc++ libstdc++-devel libstdc++-static libxml2 libxml2-devel m4 .x86_64 nfs-utils okular perl pkgconfig pixman-devel python3 python3-devel tcsh time unzip wget
	echo $PASSWD | sudo -S apt -y install python3-dateutil

	echo $PASSWD | sudo -S dnf -y groupinstall "Development Tools"
	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade
	echo " "

	echo "old version of GNU detected"
	echo $PASSWD | sudo -S yum install centos-release-scl -y
	echo $PASSWD | sudo -S yum clean all
	echo $PASSWD | sudo -S yum remove devtoolset-11*
	echo $PASSWD | sudo -S yum install devtoolset-11
	echo $PASSWD | sudo -S yum install devtoolset-11-\* -y
	source /opt/rh/devtoolset-11/enable
	gcc --version
	echo $PASSWD | sudo -S yum install rh-python38* -y
	source /opt/rh/rh-python38/enable
	python3 -V
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

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh "${WRF_FOLDER}"/MET-$met_Version_number
	tar -xvzf tar_files.tgz -C "${WRF_FOLDER}"/MET-$met_Version_number
	cp v$met_Version_number.tar.gz "${WRF_FOLDER}"/MET-$met_Version_number/tar_files
	cd "${WRF_FOLDER}"/MET-$met_Version_number

	# Installation of Model Evaluation Tools

	cd "${WRF_FOLDER}"/MET-$met_Version_number

	export PYTHON_VERSION=$(/opt/rh/rh-python38/root/usr/bin/python3 -V 2>&1 | awk '{print $2}')
	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION

	export CC=gcc
	export CXX=g++
	export CFLAGS="-fPIC -fPIE -O3"
	export FC=gfortran
	export F77=gfortran
	export F90=gfortran
	export gcc_version=$(gcc -dumpfullversion)
	export TEST_BASE="${WRF_FOLDER}"/MET-$met_Version_number
	export COMPILER=gnu_$gcc_version
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/opt/rh/rh-python38/root/usr/
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

	export MAKE_ARGS="-j 4"

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
	tar -xvzf v$METPLUS_Version.tar.gz -C "${WRF_FOLDER}"

	# Insatlllation of Model Evaluation Tools Plus
	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = "${WRF_FOLDER}"/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data

	# Testing if installation of MET & METPlus was sucessfull
	# If you see in terminal "METplus has successfully finished running."
	# Then MET & METPLUS is sucessfully installed

	echo 'Testing MET & METPLUS Installation.'
	"${WRF_FOLDER}"/METplus-$METPLUS_Version/ush/run_metplus.py -c "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/use_cases/met_tool_wrapper/GridStat/GridStat.conf

	# Check if the previous command was successful
	if [ $? -eq 0 ]; then
		echo " "
		echo "MET and METPLUS successfully installed with GNU compilers."
		echo " "
		export PATH="${WRF_FOLDER}"/METplus-$METPLUS_Version/ush:$PATH
	else
		echo " "
		echo "Error: MET and METPLUS installation failed."
		echo " "
		# Handle the error case, e.g., exit the script or retry installation
		exit 1
	fi
fi

# if [ "$macos_64bit_GNU" = "1" ] && [ "$DTC_MET" = "1" ] && [ "$MAC_CHIP" = "Intel" ]; then
# 	echo "MET INSTALLING"
# 	# Update Homebrew and get list of outdated packages
# 	brew update
# 	outdated_packages=$(brew outdated --quiet)

# 	# List of packages to check/install
# 	packages=("automake" "autoconf" "bison" "cmake" "curl" "flex" "gdal" "gedit" "gcc@12" "gnu-sed" "imagemagick" "java" "ksh" "libtool" "make" "m4" "python@3.12" "python-tk@3.12" "snapcraft" "tcsh" "wget" "xauth" "xorgproto" "xorgrgb" "xquartz")

# 	for pkg in "${packages[@]}"; do
# 		if brew list "$pkg" &>/dev/null; then
# 			echo "$pkg is already installed."
# 			if [[ $outdated_packages == *"$pkg"* ]]; then
# 				echo "$pkg has a newer version available. Upgrading..."
# 				brew upgrade "$pkg"
# 			fi
# 		else
# 			echo "$pkg is not installed. Installing..."
# 			brew install "$pkg"
# 		fi
# 		sleep 1
# 	done

# 	# Install python-dateutil using pip
# 	pip3.12 install python-dateutil --break-system-packages
# 	pip3.12 install python-dateutil==2.8 --break-system-packages
# 	#Directory Listings
# 	mkdir $HOME/DTC
# 	export WRF_FOLDER=$HOME/DTC

# 	mkdir "${WRF_FOLDER}"/MET-$met_Version_number
# 	mkdir "${WRF_FOLDER}"/MET-$met_Version_number/Downloads
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

# 	#Symlink to avoid clang conflicts with compilers
# 	#default gcc path /usr/bin/gcc
# 	#default homebrew path /usr/local/bin

# 	# Create or update the symbolic links for GCC, G++, and GFortran
# 	echo "Linking the latest GCC version 13"
# 	echo $PASSWD | sudo -S ln -sf /usr/local/bin/gcc-12 /usr/local/bin/gcc

# 	echo $PASSWD | sudo -S ln -sf /usr/local/bin/g++-12 /usr/local/bin/g++


# 	echo $PASSWD | sudo -S ln -sf /usr/local/bin/gfortran-12 /usr/local/bin/gfortran

# 	echo "Updated symbolic links for GCC, G++, and GFortran."
# 	echo $PASSWD | sudo -S ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3

# 	gcc --version
# 	g++ --version
# 	gfortran --version
# 	python3 --version

# 	cd "${WRF_FOLDER}"/MET-$met_Version_number/Downloads

# 	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

# 	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

# 	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

# 	cp compile_MET_all.sh "${WRF_FOLDER}"/MET-$met_Version_number
# 	tar -xvzf tar_files.tgz -C "${WRF_FOLDER}"/MET-$met_Version_number
# 	cp v$met_Version_number.tar.gz "${WRF_FOLDER}"/MET-$met_Version_number/tar_files
# 	cd "${WRF_FOLDER}"/MET-$met_Version_number

# 	cd "${WRF_FOLDER}"/MET-$met_Version_number

# 	export PYTHON_VERSION=$(python3 -V 2>1 | awk '{print $2}')
# 	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
# 	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
# 	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION

# 	export CC=/usr/local/bin/gcc
# 	export CXX=/usr/local/bin/g++
# 	export CFLAGS="-fPIC -fPIE -O3"
# 	export FC=/usr/local/bin/gfortran
# 	export F77=/usr/local/bin/gfortran
# 	export F90=/usr/local/bin/gfortran
# 	export gcc_version=$(gcc -dumpfullversion)
# 	export TEST_BASE="${WRF_FOLDER}"/MET-$met_Version_number
# 	export COMPILER=gnu_$gcc_version
# 	export MET_SUBDIR=${TEST_BASE}
# 	export MET_TARBALL=v$met_Version_number.tar.gz
# 	export USE_MODULES=FALSE
# 	export MET_PYTHON=/usr/local
# 	export MET_PYTHON_CC="-I${MET_PYTHON}/include/python${PYTHON_VERSION_COMBINED}"
# 	export MET_PYTHON_LD="$(python3.12-config --ldflags) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"
# 	export SET_D64BIT=FALSE

# 	echo "CC=$CC"
# 	echo "CXX=$CXX"
# 	echo "FC=$FC"
# 	echo "F77=$F77"
# 	echo "F90=$F90"
# 	echo "gcc_version=$gcc_version"
# 	echo "TEST_BASE=$TEST_BASE"
# 	echo "COMPILER=$COMPILER"
# 	echo "MET_SUBDIR=$MET_SUBDIR"
# 	echo "MET_TARBALL=$MET_TARBALL"
# 	echo "USE_MODULES=$USE_MODULES"
# 	echo "MET_PYTHON=$MET_PYTHON"
# 	echo "MET_PYTHON_CC=$MET_PYTHON_CC"
# 	echo "MET_PYTHON_LD=$MET_PYTHON_LD"
# 	echo "SET_D64BIT=$SET_D64BIT"

# 	export MAKE_ARGS="-j 4"

# 	chmod 775 compile_MET_all.sh

# 	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

# 	export PATH="${WRF_FOLDER}"/MET-$met_Version_number/bin:$PATH

# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

# 	#Downloading METplus and untarring files

# 	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
# 	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
# 	tar -xvzf v$METPLUS_Version.tar.gz -C "${WRF_FOLDER}"

# 	# Insatlllation of Model Evaluation Tools Plus
# 	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/metplus_config

# 	sed -i'' -e "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = "${WRF_FOLDER}"/MET-$met_Version_number|" defaults.conf
# 	sed -i'' -e "s|INPUT_BASE = /path/to|INPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
# 	sed -i'' -e "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output|" defaults.conf

# 	# Downloading Sample Data

# 	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
# 	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
# 	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data

# 	# Testing if installation of MET & METPlus was sucessfull
# 	# If you see in terminal "METplus has successfully finished running."
# 	# Then MET & METPLUS is sucessfully installed

# 	echo 'Testing MET & METPLUS Installation.'
# 	$WRF_FOLDER/METplus-$METPLUS_Version/ush/run_metplus.py -c $WRF_FOLDER/METplus-$METPLUS_Version/parm/use_cases/met_tool_wrapper/GridStat/GridStat.conf

# 	# Check if the previous command was successful
# 	if [ $? -eq 0 ]; then
# 		echo "MET and METPLUS successfully installed with GNU compilers."
# 		export PATH=$WRF_FOLDER/METplus-$METPLUS_Version/ush:$PATH
# 	else
# 		echo "Error: MET and METPLUS installation failed."
# 		# Handle the error case, e.g., exit the script or retry installation
# 		exit 1
# 	fi
# fi

# if [ "$macos_64bit_GNU" = "1" ] && [ "$DTC_MET" = "1" ] && [ "$MAC_CHIP" = "ARM" ]; then
# 	echo "MET INSTALLING"
# 	# Update Homebrew and get list of outdated packages
# 	brew update
# 	outdated_packages=$(brew outdated --quiet)

# 	# List of packages to check/install
# 	packages=("automake" "autoconf" "bison" "cmake" "curl" "flex" "gdal" "gedit" "gcc@12" "gnu-sed" "imagemagick" "java" "ksh" "libtool" "make" "m4" "python@3.12" "python-tk@3.12" "snapcraft" "tcsh" "wget" "xauth" "xorgproto" "xorgrgb" "xquartz")

# 	for pkg in "${packages[@]}"; do
# 		if brew list "$pkg" &>/dev/null; then
# 			echo "$pkg is already installed."
# 			if [[ $outdated_packages == *"$pkg"* ]]; then
# 				echo "$pkg has a newer version available. Upgrading..."
# 				brew upgrade "$pkg"
# 			fi
# 		else
# 			echo "$pkg is not installed. Installing..."
# 			brew install "$pkg"
# 		fi
# 		sleep 1
# 	done

# 	# Install python-dateutil using pip
# 	pip3.12 install python-dateutil --break-system-packages
# 	pip3.12 install python-dateutil==2.8 --break-system-packages
# 	#Directory Listings
# 	mkdir $HOME/DTC
# 	export WRF_FOLDER=$HOME/DTC

# 	mkdir "${WRF_FOLDER}"/MET-$met_Version_number
# 	mkdir "${WRF_FOLDER}"/MET-$met_Version_number/Downloads
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

# 	# Unlink previous GCC, G++, and GFortran symlinks in Homebrew path to avoid conflicts
# 	echo $PASSWD | sudo -S unlink /opt/homebrew/bin/gfortran
# 	echo $PASSWD | sudo -S unlink /opt/homebrew/bin/gcc
# 	echo $PASSWD | sudo -S unlink /opt/homebrew/bin/g++

# 	# Source the bashrc to ensure environment variables are loaded
# 	source ~/.bashrc

# 	# Check current versions of gcc, g++, and gfortran (this should show no version if unlinked)
# 	gcc --version
# 	g++ --version
# 	gfortran --version

# 	# Navigate to the Homebrew binaries directory
# 	cd /opt/homebrew/bin

# 	# Find the latest version of GCC, G++, and GFortran
# 	latest_gcc=$(ls gcc-* 2>/dev/null | grep -o 'gcc-[0-9]*' | sort -V | tail -n 1)
# 	latest_gpp=$(ls g++-* 2>/dev/null | grep -o 'g++-[0-9]*' | sort -V | tail -n 1)
# 	latest_gfortran=$(ls gfortran-* 2>/dev/null | grep -o 'gfortran-[0-9]*' | sort -V | tail -n 1)

# 	# Check if the latest versions were found, and link them
# 	if [ -n "gcc-12" ]; then
# 		echo "Linking the latest GCC version: gcc-12"
# 		echo $PASSWD | sudo -S ln -sf gcc-12 gcc
# 	else
# 		echo "No GCC version found."
# 	fi

# 	if [ -n "g++-12" ]; then
# 		echo "Linking the latest G++ version: g++-12"
# 		echo $PASSWD | sudo -S ln -sf g++-12 g++
# 	else
# 		echo "No G++ version found."
# 	fi

# 	if [ -n "gfortran-12" ]; then
# 		echo "Linking the latest GFortran version: gfortran-12"
# 		echo $PASSWD | sudo -S ln -sf gfortran-12 gfortran
# 	else
# 		echo "No GFortran version found."
# 	fi

# 	# Return to the home directory
# 	cd

# 	# Source bashrc and bash_profile to reload the environment settings
# 	source ~/.bashrc
# 	source ~/.bash_profile

# 	# Check if the versions were successfully updated
# 	gcc --version
# 	g++ --version
# 	gfortran --version
# 	python3 --version

# 	cd "${WRF_FOLDER}"/MET-$met_Version_number/Downloads

# 	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

# 	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

# 	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

# 	cp compile_MET_all.sh "${WRF_FOLDER}"/MET-$met_Version_number
# 	tar -xvzf tar_files.tgz -C "${WRF_FOLDER}"/MET-$met_Version_number
# 	cp v$met_Version_number.tar.gz "${WRF_FOLDER}"/MET-$met_Version_number/tar_files
# 	cd "${WRF_FOLDER}"/MET-$met_Version_number

# 	cd "${WRF_FOLDER}"/MET-$met_Version_number

# 	export PYTHON_VERSION=$(python3 -V 2>1 | awk '{print $2}')
# 	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
# 	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
# 	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION

# 	export CC=/usr/local/bin/gcc
# 	export CXX=/usr/local/bin/g++
# 	export CFLAGS="-fPIC -fPIE -O3 -Wno-implicit-function-declaration -Wno-implicit-int"
# 	export FC=/usr/local/bin/gfortran
# 	export F77=/usr/local/bin/gfortran
# 	export F90=/usr/local/bin/gfortran
# 	export gcc_version=$(gcc -dumpfullversion)
# 	export TEST_BASE="${WRF_FOLDER}"/MET-$met_Version_number
# 	export COMPILER=gnu_$gcc_version
# 	export MET_SUBDIR=${TEST_BASE}
# 	export MET_TARBALL=v$met_Version_number.tar.gz
# 	export USE_MODULES=FALSE
# 	export MET_PYTHON=/usr/local
# 	export MET_PYTHON_CC="-I${MET_PYTHON}/include/python${PYTHON_VERSION_COMBINED}"
# 	export MET_PYTHON_LD="$(python3.12-config --ldflags) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"
# 	export SET_D64BIT=FALSE

# 	echo "CC=$CC"
# 	echo "CXX=$CXX"
# 	echo "FC=$FC"
# 	echo "F77=$F77"
# 	echo "F90=$F90"
# 	echo "gcc_version=$gcc_version"
# 	echo "TEST_BASE=$TEST_BASE"
# 	echo "COMPILER=$COMPILER"
# 	echo "MET_SUBDIR=$MET_SUBDIR"
# 	echo "MET_TARBALL=$MET_TARBALL"
# 	echo "USE_MODULES=$USE_MODULES"
# 	echo "MET_PYTHON=$MET_PYTHON"
# 	echo "MET_PYTHON_CC=$MET_PYTHON_CC"
# 	echo "MET_PYTHON_LD=$MET_PYTHON_LD"
# 	echo "SET_D64BIT=$SET_D64BIT"

# 	export MAKE_ARGS="-j 4"

# 	chmod 775 compile_MET_all.sh

# 	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

# 	export PATH="${WRF_FOLDER}"/MET-$met_Version_number/bin:$PATH

# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output
# 	mkdir "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads

# 	#Downloading METplus and untarring files

# 	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
# 	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
# 	tar -xvzf v$METPLUS_Version.tar.gz -C "${WRF_FOLDER}"

# 	# Insatlllation of Model Evaluation Tools Plus
# 	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/parm/metplus_config

# 	sed -i'' -e "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = "${WRF_FOLDER}"/MET-$met_Version_number|" defaults.conf
# 	sed -i'' -e "s|INPUT_BASE = /path/to|INPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
# 	sed -i'' -e "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = "${WRF_FOLDER}"/METplus-$METPLUS_Version/Output|" defaults.conf

# 	# Downloading Sample Data

# 	cd "${WRF_FOLDER}"/METplus-$METPLUS_Version/Downloads
# 	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
# 	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C "${WRF_FOLDER}"/METplus-$METPLUS_Version/Sample_Data

# 	# Testing if installation of MET & METPlus was sucessfull
# 	# If you see in terminal "METplus has successfully finished running."
# 	# Then MET & METPLUS is sucessfully installed

# 	echo 'Testing MET & METPLUS Installation.'
# 	$WRF_FOLDER/METplus-$METPLUS_Version/ush/run_metplus.py -c $WRF_FOLDER/METplus-$METPLUS_Version/parm/use_cases/met_tool_wrapper/GridStat/GridStat.conf

# 	# Check if the previous command was successful
# 	if [ $? -eq 0 ]; then
# 		echo "MET and METPLUS successfully installed with GNU compilers."
# 		export PATH=$WRF_FOLDER/METplus-$METPLUS_Version/ush:$PATH
# 	else
# 		echo "Error: MET and METPLUS installation failed."
# 		# Handle the error case, e.g., exit the script or retry installation
# 		exit 1
# 	fi
# fi

#####################################BASH Script Finished##############################

end=$(date)
END=$(date +"%s")
DIFF=$(($END - $START))
echo "Install Start Time: ${start}"
echo "Install End Time: ${end}"
echo "Install Duration: $(($DIFF / 3600)) hours $((($DIFF % 3600) / 60)) minutes $(($DIFF % 60)) seconds"
