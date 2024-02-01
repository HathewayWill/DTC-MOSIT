#!/bin/bash
export METPLUS_Version=5.1.0
export met_Version_number=11.1.0
export met_VERSION_number=11.1
export METPLUS_DATA=5.1



start=$(date)
START=$(date +"%s")

############################### System Architecture Type #################
# 32 or 64 bit
##########################################################################
export SYS_ARCH=$(uname -m)

if [ "$SYS_ARCH" = "x86_64" ] || [ "$SYS_ARCH" = "arm64" ]; then
	export SYSTEMBIT="64"
else
	export SYSTEMBIT="32"
fi

if [ "$SYS_ARCH" = "arm64" ]; then
	export MAC_CHIP="ARM"
else
	export MAC_CHIP="Intel"
fi

############################# System OS Version #############################
# Macos or linux
# Make note that this script only works for Debian Linux kernals
#############################################################################
export SYS_OS=$(uname -s)

if [ "$SYS_OS" = "Darwin" ]; then
	export SYSTEMOS="MacOS"
elif [ "$SYS_OS" = "Linux" ]; then
	export SYSTEMOS="Linux"
fi

########## Centos Test #############
if [ "$SYSTEMOS" = "Linux" ]; then
	export YUM=$(command -v yum)
	if [ "$YUM" != "" ]; then
		echo " yum found"
		echo "Your system is a CentOS based system"
		export SYSTEMOS=CentOSS
	fi

fi

############################### Intel or GNU Compiler Option #############

if [ "$SYSTEMBIT" = "32" ] && [ "$SYSTEMOS" = "CentOS" ]; then
	echo "Your system is not compatibile with this script."
	exit
fi

if [ "$SYSTEMBIT" = "64" ] && [ "$SYSTEMOS" = "CentOS" ]; then
	echo "Your system is a 64bit version of CentOS Linux Kernal"
	echo " "
	echo "Intel compilers are not compatibile with this script"
	echo " "
	echo "Setting compiler to GNU"
	export Centos_64bit_GNU=1
fi

if [ "$Centos_64bit_GNU" = "1" ]; then

	export gcc_test_version=$(gcc -dumpversion 2>&1 | awk '{print $1}')
	export gcc_test_version_major=$(echo $gcc_test_version | awk -F. '{print $1}')
	export gcc_version_9="9"

	if [[ $gcc_test_version_major -lt $gcc_version_9 ]]; then
		export Centos_64bit_GNU=2
		echo " OLD GNU FILES FOUND"
	fi
fi


if [ "$SYSTEMBIT" = "32" ] && [ "$SYSTEMOS" = "MacOS" ]; then
	echo "Your system is not compatibile with this script."
	exit
fi

if [ "$SYSTEMBIT" = "64" ] && [ "$SYSTEMOS" = "MacOS" ] && [ "$MAC_CHIP" = "Intel" ]; then
	echo "Your system is a 64bit version of MacOS"
	echo " "
	echo "Intel compilers are not compatibile with this script"
	echo " "
	echo "Setting compiler to GNU"
	export macos_64bit_GNU=1
	echo " "
	echo "Xcode Command Line Tools & Homebrew are required for this script."
	echo " "
	echo "Installing Homebrew and Xcode Command Line Tools now"
	echo " "
	echo "Please enter password when prompted"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

	(
		echo
		echo 'eval "$(/usr/local/bin/brew shellenv)"'
	) >>~/.profile
	eval "$(/usr/local/bin/brew shellenv)"

	chsh -s /bin/bash

fi

if [ "$SYSTEMBIT" = "64" ] && [ "$SYSTEMOS" = "MacOS" ] && [ "$MAC_CHIP" = "ARM" ]; then
	echo "Your system is a 64bit version of MacOS with arm64"
	echo " "
	echo "Intel compilers are not compatibile with this script"
	echo " "
	echo "Setting compiler to GNU"
	export macos_64bit_GNU=1
	echo " "
	echo "Xcode Command Line Tools & Homebrew are required for this script."
	echo " "
	echo "Installing Homebrew and Xcode Command Line Tools now"
	echo " "
	echo "Please enter password when prompted"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

	(
		echo
		echo 'eval "$(/opt/homebrew/bin/brew shellenv)"'
	) >>~/.profile
	eval "$(/opt/homebrew/bin/brew shellenv)"

	chsh -s /bin/bash

fi

if [ "$SYSTEMBIT" = "64" ] && [ "$SYSTEMOS" = "Linux" ]; then
	echo "Your system is 64bit version of Debian Linux Kernal"
	echo " "
	while read -r -p "Which compiler do you want to use?
  -Intel
   --Please note that Hurricane WRF (HWRF) is only compatibile with Intel Compilers.

  -GNU

  Please answer Intel or GNU and press enter (case sensative).
  " yn; do

		case $yn in
		Intel)
			echo "-------------------------------------------------- "
			echo " "
			echo "Intel is selected for installation"
			export Ubuntu_64bit_Intel=1
			break
			;;
		GNU)
			echo "-------------------------------------------------- "
			echo " "
			echo "GNU is selected for installation"
			export Ubuntu_64bit_GNU=1
			break
			;;
		*)
			echo " "
			echo "Please answer Intel or GNU (case sensative)."
			;;

		esac
	done
fi

if [ "$SYSTEMBIT" = "32" ] && [ "$SYSTEMOS" = "Linux" ]; then
	echo "Your system is not compatibile with this script."
	exit
fi

############################# Enter sudo users information #############################
echo "-------------------------------------------------- "
while true; do
	echo " "
	read -r -s -p "
  Password is only save locally and will not be seen when typing.
  Please enter your sudo password:

  " yn
	export PASSWD=$yn
	echo "-------------------------------------------------- "
	break
done

echo " "
echo "Beginning Installation"
echo " "

############################ DTC's MET & METPLUS ##################################################

###################################################################################################


if [ "$Ubuntu_64bit_Intel" = "1" ] ; then

	echo $PASSWD | sudo -S sudo apt install git
	echo "MET INSTALLING"
	echo $PASSWD | sudo -S apt -y update
	echo $PASSWD | sudo -S apt -y upgrade && sudo -S apt -y autoremove

	# download the key to system keyring; this and the following echo command are
	# needed in order to install the Intel compilers
	wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB |
		gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg >/dev/null

	# add signed entry to apt sources and configure the APT client to use Intel repository:
	echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list

	# this update should get the Intel package info from the Intel repository
	echo $PASSWD | sudo -S apt -y update
	echo $PASSWD | sudo -S apt -y upgrade && sudo -S apt -y autoremove
	echo $PASSWD | sudo -S apt -y install autoconf automake bison build-essential byacc cmake csh curl default-jdk default-jre emacs flex g++ gawk gcc gfortran git ksh libcurl4-openssl-dev libjpeg-dev libncurses5 libncurses6 libpixman-1-dev libpng-dev libtool libxml2 libxml2-dev m4 make mlocate ncview okular openbox pipenv pkg-config python2 python2-dev python3 python3-dev python3-pip tcsh unzip xauth xorg time

	# install the Intel compilers
	echo $PASSWD | sudo -S apt -y install intel-basekit
	echo $PASSWD | sudo -S apt -y install intel-hpckit
	echo $PASSWD | sudo -S apt -y install intel-oneapi-python

	echo $PASSWD | sudo -S apt -y update

	# make sure some critical packages have been installed
	which cmake pkg-config make gcc g++ gfortran

	# add the Intel compiler file paths to various environment variables
	source /opt/intel/oneapi/setvars.sh

	# some of the libraries we install below need one or more of these variables
	export CC=icc
	export CXX=icpc
	export FC=ifort
	export F77=ifort
	export F90=ifort
	export MPIFC=mpiifort
	export MPIF77=mpiifort
	export MPIF90=mpiifort
	export MPICC=mpiicc
	export MPICXX=mpiicpc
	export CFLAGS="-fPIC -fPIE -O3 -diag-disable=10441 "
	export FFLAGS="-m64"
	export FCFLAGS="-m64"
	#########################

	#Downloading latest dateutil due to python3.8 running old version.
	pip3 install python-dateutil==2.8
	pip3 install python-dateutil

	mkdir $HOME/DTC
  export WRF_FOLDER=$HOME/DTC


	mkdir $WRF_FOLDER/MET-$met_Version_number
	mkdir $WRF_FOLDER/MET-$met_Version_number/Downloads
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Downloading MET and untarring files
	#Note weblinks change often update as needed.
	cd $WRF_FOLDER/MET-$met_Version_number/Downloads
	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh $WRF_FOLDER/MET-$met_Version_number
	tar -xvzf tar_files.tgz -C $WRF_FOLDER/MET-$met_Version_number
	cp v$met_Version_number.tar.gz $WRF_FOLDER/MET-$met_Version_number/tar_files
	cd $WRF_FOLDER/MET-$met_Version_number

	cd $WRF_FOLDER/MET-$met_Version_number

	export PYTHON_VERSION=$(/opt/intel/oneapi/intelpython/latest/bin/python3 -V 2>&1 | awk '{print $2}')
	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION

	export CC=icc
	export CXX=icpc
	export FC=ifort
	export F77=ifort
	export F90=ifort
	export gcc_version=$(icc -dumpversion -diag-disable=10441)
	export TEST_BASE=$WRF_FOLDER/MET-$met_Version_number
	export COMPILER=intel_$gcc_version
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/opt/intel/oneapi/intelpython/python${PYTHON_VERSION_COMBINED}
	export MET_PYTHON_CC="$(python3-config --cflags --embed)"
	export MET_PYTHON_LD="$(python3-config --ldflags --embed) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"
	export SET_D64BIT=FALSE

	export MAKE_ARGS="-j 4"


	chmod 775 compile_MET_all.sh

	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

	export PATH=$WRF_FOLDER/MET-$met_Version_number/bin:$PATH #Add MET executables to path

	#Basic Package Management for Model Evaluation Tools (METplus)

	echo $PASSWD | sudo -S apt -y update
	echo $PASSWD | sudo -S apt -y upgrade && sudo -S apt -y autoremove

	#Directory Listings for Model Evaluation Tools (METplus

	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Output
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Downloading METplus and untarring files

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
	tar -xvzf v$METPLUS_Version.tar.gz -C $WRF_FOLDER

	# Insatlllation of Model Evaluation Tools Plus
	cd $WRF_FOLDER/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = $WRF_FOLDER/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data

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

if [ "$Ubuntu_64bit_GNU" = "1" ] ; then

	echo $PASSWD | sudo -S sudo apt install git
	echo "MET INSTALLING"
	export HOME=$(
		cd
		pwd
	)
	#Basic Package Management for Model Evaluation Tools (MET)

	#############################basic package managment############################
	echo $PASSWD | sudo -S apt -y update
	echo $PASSWD | sudo -S apt -y upgrade && sudo -S apt -y autoremove
	echo $PASSWD | sudo -S apt -y install autoconf automake bison build-essential byacc cmake csh curl default-jdk default-jre emacs flex g++ gawk gcc gfortran git ksh libcurl4-openssl-dev libjpeg-dev libncurses5 libncurses6 libpixman-1-dev libpng-dev libtool libxml2 libxml2-dev m4 make mlocate ncview okular openbox pipenv pkg-config python2 python2-dev python3 python3-dev python3-pip tcsh unzip xauth xorg time

	#Downloading latest dateutil due to python3.8 running old version.
	pip3 install python-dateutil==2.8
	pip3 install python-dateutil

	mkdir $HOME/DTC
  export WRF_FOLDER=$HOME/DTC


	mkdir $WRF_FOLDER/MET-$met_Version_number
	mkdir $WRF_FOLDER/MET-$met_Version_number/Downloads
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Downloading MET and untarring files
	#Note weblinks change often update as needed.
	cd $WRF_FOLDER/MET-$met_Version_number/Downloads

	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh $WRF_FOLDER/MET-$met_Version_number
	tar -xvzf tar_files.tgz -C $WRF_FOLDER/MET-$met_Version_number
	cp v$met_Version_number.tar.gz $WRF_FOLDER/MET-$met_Version_number/tar_files
	cd $WRF_FOLDER/MET-$met_Version_number

	# Installation of Model Evaluation Tools
	export CC=gcc
	export CXX=g++
	export FC=gfortran
	export F77=gfortran
	export CFLAGS="-fPIC -fPIE -O3"

	cd $WRF_FOLDER/MET-$met_Version_number
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
	export TEST_BASE=$WRF_FOLDER/MET-$met_Version_number
	export COMPILER=gnu_$gcc_version
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/usr
	export MET_PYTHON_CC="$(python3-config --cflags --embed)"
	export MET_PYTHON_LD="$(python3-config --ldflags --embed) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"
	export SET_D64BIT=FALSE

	export MAKE_ARGS="-j 4"

	chmod 775 compile_MET_all.sh

	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

	export PATH=$WRF_FOLDER/MET-$met_Version_number/bin:$PATH

	#basic Package Management for Model Evaluation Tools (METplus)

	echo $PASSWD | sudo -S apt -y update
	echo $PASSWD | sudo -S apt -y upgrade && sudo -S apt -y autoremove

	#Directory Listings for Model Evaluation Tools (METplus

	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Output
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Downloading METplus and untarring files

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
	tar -xvzf v$METPLUS_Version.tar.gz -C $WRF_FOLDER

	# Insatlllation of Model Evaluation Tools Plus
	cd $WRF_FOLDER/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = $WRF_FOLDER/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data

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

if [ "$Centos_64bit_GNU" = "1" ] ; then
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
	echo $PASSWD | sudo -S dnf -y install autoconf automake bzip2 bzip2-devel byacc cairo-devel cmake cpp curl curl-devel flex flex-devel fontconfig-devel fontconfig-devel.x86_64 gcc gcc-c++ gcc-gfortran git java-11-openjdk java-11-openjdk-devel ksh libX11-devel libX11-devel.x86_64 libXaw libXaw-devel libXext-devel libXext-devel.x86_64 libXmu-devel libXrender-devel libXrender-devel.x86_64 libstdc++ libstdc++-devel libstdc++-static libxml2 libxml2-devel m4 mlocate mlocate.x86_64 nfs-utils okular perl pkgconfig pixman-devel python3 python3-devel tcsh time unzip wget
	pip3 install python-dateutil
	echo $PASSWD | sudo -S dnf -y groupinstall "Development Tools"
	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade
	echo " "

	mkdir $HOME/DTC
	export WRF_FOLDER=$HOME/DTC

	mkdir $WRF_FOLDER/MET-$met_Version_number
	mkdir $WRF_FOLDER/MET-$met_Version_number/Downloads
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Downloading MET and untarring files
	#Note weblinks change often update as needed.
	cd $WRF_FOLDER/MET-$met_Version_number/Downloads

	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh $WRF_FOLDER/MET-$met_Version_number
	tar -xvzf tar_files.tgz -C $WRF_FOLDER/MET-$met_Version_number
	cp v$met_Version_number.tar.gz $WRF_FOLDER/MET-$met_Version_number/tar_files
	cd $WRF_FOLDER/MET-$met_Version_number

	# Installation of Model Evaluation Tools

	cd $WRF_FOLDER/MET-$met_Version_number

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
	export TEST_BASE=$WRF_FOLDER/MET-$met_Version_number
	export COMPILER=gnu_$gcc_version
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/usr
	export MET_PYTHON_CC="$(python3-config --cflags --embed)"
	export MET_PYTHON_LD="$(python3-config --ldflags --embed) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"
	export SET_D64BIT=FALSE

	export MAKE_ARGS="-j 4"

	chmod 775 compile_MET_all.sh

	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

	export PATH=$WRF_FOLDER/MET-$met_Version_number/bin:$PATH

	#basic Package Management for Model Evaluation Tools (METplus)

	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade

	#Directory Listings for Model Evaluation Tools (METplus

	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Output
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Downloading METplus and untarring files

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
	tar -xvzf v$METPLUS_Version.tar.gz -C $WRF_FOLDER

	# Insatlllation of Model Evaluation Tools Plus
	cd $WRF_FOLDER/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = $WRF_FOLDER/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data

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

if [ "$Centos_64bit_GNU" = "2" ] ; then

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
	echo $PASSWD | sudo -S dnf -y install autoconf automake bzip2 bzip2-devel byacc cairo-devel cmake cpp curl curl-devel flex flex-devel fontconfig-devel fontconfig-devel.x86_64 gcc gcc-c++ gcc-gfortran git java-11-openjdk java-11-openjdk-devel ksh libX11-devel libX11-devel.x86_64 libXaw libXaw-devel libXext-devel libXext-devel.x86_64 libXmu-devel libXrender-devel libXrender-devel.x86_64 libstdc++ libstdc++-devel libstdc++-static libxml2 libxml2-devel m4 mlocate mlocate.x86_64 nfs-utils okular perl pkgconfig pixman-devel python3 python3-devel tcsh time unzip wget
	echo $PASSWD | sudo -S pip3 install python-dateutil
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
	echo $PASSWD | sudo echo $PASSWD | sudo -S ./opt/rh/rh-python38/root/bin/pip3.8 install python-dateutil
	mkdir $HOME/DTC
  export WRF_FOLDER=$HOME/DTC

	mkdir $WRF_FOLDER/MET-$met_Version_number
	mkdir $WRF_FOLDER/MET-$met_Version_number/Downloads
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Downloading MET and untarring files
	#Note weblinks change often update as needed.
	cd $WRF_FOLDER/MET-$met_Version_number/Downloads

	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh $WRF_FOLDER/MET-$met_Version_number
	tar -xvzf tar_files.tgz -C $WRF_FOLDER/MET-$met_Version_number
	cp v$met_Version_number.tar.gz $WRF_FOLDER/MET-$met_Version_number/tar_files
	cd $WRF_FOLDER/MET-$met_Version_number

	# Installation of Model Evaluation Tools

	cd $WRF_FOLDER/MET-$met_Version_number

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
	export TEST_BASE=$WRF_FOLDER/MET-$met_Version_number
	export COMPILER=gnu_$gcc_version
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/opt/rh/rh-python38/root/usr/
	export MET_PYTHON_CC="$(python3-config --cflags --embed)"
	export MET_PYTHON_LD="$(python3-config --ldflags --embed) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"
	export SET_D64BIT=FALSE

	export MAKE_ARGS="-j 4"

	chmod 775 compile_MET_all.sh

	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

	export PATH=$WRF_FOLDER/MET-$met_Version_number/bin:$PATH

	#basic Package Management for Model Evaluation Tools (METplus)

	echo $PASSWD | sudo -S dnf -y update
	echo $PASSWD | sudo -S dnf -y upgrade

	#Directory Listings for Model Evaluation Tools (METplus

	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Output
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Downloading METplus and untarring files

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
	tar -xvzf v$METPLUS_Version.tar.gz -C $WRF_FOLDER

	# Insatlllation of Model Evaluation Tools Plus
	cd $WRF_FOLDER/METplus-$METPLUS_Version/parm/metplus_config

	sed -i "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = $WRF_FOLDER/MET-$met_Version_number|" defaults.conf
	sed -i "s|INPUT_BASE = /path/to|INPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data

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

if [ "$macos_64bit_GNU" = "1" ]  && [ "$MAC_CHIP" = "Intel" ]; then
	echo "MET INSTALLING"

# Update Homebrew and get list of outdated packages
brew update
outdated_packages=$(brew outdated --quiet)

# List of packages to check/install
packages=("automake" "autoconf" "bison" "cmake" "curl" "flex" "gdal" "gedit" "gcc@12" "gnu-sed" "imagemagick" "java" "ksh" "libtool" "make" "m4" "python@3.10" "snapcraft" "tcsh" "wget" "xauth" "xorgproto" "xorgrgb" "xquartz")

for pkg in "${packages[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        echo "$pkg is already installed."
        if [[ $outdated_packages == *"$pkg"* ]]; then
            echo "$pkg has a newer version available. Upgrading..."
            brew upgrade "$pkg"
        fi
    else
        echo "$pkg is not installed. Installing..."
        brew install "$pkg"
    fi
    sleep 1
done

# Install python-dateutil using pip
pip3.10 install python-dateutil
pip3.10 install python-dateutil==2.8


	mkdir $HOME/DTC
	export WRF_FOLDER=$HOME/DTC

	mkdir $WRF_FOLDER/MET-$met_Version_number
	mkdir $WRF_FOLDER/MET-$met_Version_number/Downloads
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Symlink to avoid clang conflicts with compilers
	#default gcc path /usr/bin/gcc
	#default homebrew path /usr/local/bin

	echo "Please enter password for linking GNU libraries"

	echo $PASSWD | sudo -S ln -sf /usr/local/bin/gcc-12 /usr/local/bin/gcc
	echo $PASSWD | sudo -S ln -sf /usr/local/bin/g++-12 /usr/local/bin/g++
	echo $PASSWD | sudo -S ln -sf /usr/local/bin/gfortran-12 /usr/local/bin/gfortran
	echo $PASSWD | sudo -S ln -sf /usr/local/bin/python3.10 /usr/local/bin/python3

	gcc --version
	g++ --version
	gfortran --version
	python3 --version

	cd $WRF_FOLDER/MET-$met_Version_number/Downloads

	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh $WRF_FOLDER/MET-$met_Version_number
	tar -xvzf tar_files.tgz -C $WRF_FOLDER/MET-$met_Version_number
	cp v$met_Version_number.tar.gz $WRF_FOLDER/MET-$met_Version_number/tar_files
	cd $WRF_FOLDER/MET-$met_Version_number

	cd $WRF_FOLDER/MET-$met_Version_number

	export PYTHON_VERSION=$(python3 -V 2>1 | awk '{print $2}')
	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION

	export CC=/usr/local/bin/gcc
	export CXX=/usr/local/bin/g++
	export CFLAGS="-fPIC -fPIE -O3 -Wno-implicit-function-declaration"
	export FC=/usr/local/bin/gfortran
	export F77=/usr/local/bin/gfortran
	export F90=/usr/local/bin/gfortran
	export gcc_version=$(gcc -dumpfullversion)
	export TEST_BASE=$WRF_FOLDER/MET-$met_Version_number
	export COMPILER=gnu_$gcc_version
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/usr/local
	export MET_PYTHON_CC="$(python3.10-config --cflags --embed)"
	export MET_PYTHON_LD="$(python3.10-config --ldflags --embed) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"

	export SET_D64BIT=FALSE


        export MAKE_ARGS="-j 4"

	chmod 775 compile_MET_all.sh


	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

	export PATH=$WRF_FOLDER/MET-$met_Version_number/bin:$PATH

	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Output
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Downloading METplus and untarring files

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
	tar -xvzf v$METPLUS_Version.tar.gz -C $WRF_FOLDER

	# Insatlllation of Model Evaluation Tools Plus
	cd $WRF_FOLDER/METplus-$METPLUS_Version/parm/metplus_config

	sed -i'' -e "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = $WRF_FOLDER/MET-$met_Version_number|" defaults.conf
	sed -i'' -e "s|INPUT_BASE = /path/to|INPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i'' -e "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data

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

if [ "$macos_64bit_GNU" = "1" ]  && [ "$MAC_CHIP" = "ARM" ]; then
	echo "MET INSTALLING"
# Update Homebrew and get list of outdated packages
brew update
outdated_packages=$(brew outdated --quiet)

# List of packages to check/install
packages=("automake" "autoconf" "bison" "cmake" "curl" "flex" "gdal" "gedit" "gcc@12" "gnu-sed" "imagemagick" "java" "ksh" "libtool" "make" "m4" "python@3.10" "snapcraft" "tcsh" "wget" "xauth" "xorgproto" "xorgrgb" "xquartz")

for pkg in "${packages[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        echo "$pkg is already installed."
        if [[ $outdated_packages == *"$pkg"* ]]; then
            echo "$pkg has a newer version available. Upgrading..."
            brew upgrade "$pkg"
        fi
    else
        echo "$pkg is not installed. Installing..."
        brew install "$pkg"
    fi
    sleep 1
done

# Install python-dateutil using pip
pip3.10 install python-dateutil
pip3.10 install python-dateutil==2.8

	mkdir $HOME/DTC
	export WRF_FOLDER=$HOME/DTC

	mkdir $WRF_FOLDER/MET-$met_Version_number
	mkdir $WRF_FOLDER/MET-$met_Version_number/Downloads
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Symlink to avoid clang conflicts with compilers
	#default gcc path /usr/bin/gcc
	#default homebrew path /usr/local/bin
	echo $PASSWD | sudo -S unlink /opt/homebrew/bin/gfortran
	echo $PASSWD | sudo -S unlink /opt/homebrew/bin/gcc
	echo $PASSWD | sudo -S unlink /opt/homebrew/bin/g++
	echo $PASSWD | sudo -S unlink /opt/homebrew/bin/python3

	source ~./bashrc
	gcc --version
	g++ --version
	gfortran --version

	cd /opt/homebrew/bin

	echo $PASSWD | sudo -S ln -sf gcc-12 gcc
	echo $PASSWD | sudo -S ln -sf g++-12 g++
	echo $PASSWD | sudo -S ln -sf gfortran-12 gfortran
	echo $PASSWD | sudo -S ln -sf python3.10 python3

	cd
	source ~/.bashrc
	source ~/.bash_profile
	gcc --version
	g++ --version
	gfortran --version

	cd $WRF_FOLDER/MET-$met_Version_number/Downloads

	wget -c https://raw.githubusercontent.com/dtcenter/MET/main_v$met_VERSION_number/internal/scripts/installation/compile_MET_all.sh

	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/MET/installation/tar_files.tgz

	wget -c https://github.com/dtcenter/MET/archive/refs/tags/v$met_Version_number.tar.gz

	cp compile_MET_all.sh $WRF_FOLDER/MET-$met_Version_number
	tar -xvzf tar_files.tgz -C $WRF_FOLDER/MET-$met_Version_number
	cp v$met_Version_number.tar.gz $WRF_FOLDER/MET-$met_Version_number/tar_files
	cd $WRF_FOLDER/MET-$met_Version_number

	cd $WRF_FOLDER/MET-$met_Version_number

	export PYTHON_VERSION=$(python3 -V 2>1 | awk '{print $2}')
	export PYTHON_VERSION_MAJOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $1}')
	export PYTHON_VERSION_MINOR_VERSION=$(echo $PYTHON_VERSION | awk -F. '{print $2}')
	export PYTHON_VERSION_COMBINED=$PYTHON_VERSION_MAJOR_VERSION.$PYTHON_VERSION_MINOR_VERSION

	export CC=/usr/local/bin/gcc
	export CXX=/usr/local/bin/g++
	export CFLAGS="-fPIC -fPIE -O3 -Wno-implicit-function-declaration"
	export FC=/usr/local/bin/gfortran
	export F77=/usr/local/bin/gfortran
	export F90=/usr/local/bin/gfortran
	export gcc_version=$(gcc -dumpfullversion)
	export TEST_BASE=$WRF_FOLDER/MET-$met_Version_number
	export COMPILER=gnu_$gcc_version
	export MET_SUBDIR=${TEST_BASE}
	export MET_TARBALL=v$met_Version_number.tar.gz
	export USE_MODULES=FALSE
	export MET_PYTHON=/usr/local
	export MET_PYTHON_CC="$(python3.10-config --cflags --embed)"
	export MET_PYTHON_LD="$(python3.10-config --ldflags --embed) -L${MET_PYTHON}/lib -lpython${PYTHON_VERSION_COMBINED}"

	export SET_D64BIT=FALSE

	export MAKE_ARGS="-j 4"

	chmod 775 compile_MET_all.sh


	time ./compile_MET_all.sh 2>&1 | tee compile_MET_all.log

	export PATH=$WRF_FOLDER/MET-$met_Version_number/bin:$PATH

	mkdir $WRF_FOLDER/METplus-$METPLUS_Version
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Output
	mkdir $WRF_FOLDER/METplus-$METPLUS_Version/Downloads

	#Downloading METplus and untarring files

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://github.com/dtcenter/METplus/archive/refs/tags/v$METPLUS_Version.tar.gz
	tar -xvzf v$METPLUS_Version.tar.gz -C $WRF_FOLDER

	# Insatlllation of Model Evaluation Tools Plus
	cd $WRF_FOLDER/METplus-$METPLUS_Version/parm/metplus_config

	sed -i'' -e "s|MET_INSTALL_DIR = /path/to|MET_INSTALL_DIR = $WRF_FOLDER/MET-$met_Version_number|" defaults.conf
	sed -i'' -e "s|INPUT_BASE = /path/to|INPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data|" defaults.conf
	sed -i'' -e "s|OUTPUT_BASE = /path/to|OUTPUT_BASE = $WRF_FOLDER/METplus-$METPLUS_Version/Output|" defaults.conf

	# Downloading Sample Data

	cd $WRF_FOLDER/METplus-$METPLUS_Version/Downloads
	wget -c https://dtcenter.ucar.edu/dfiles/code/METplus/METplus_Data/v$METPLUS_DATA/sample_data-met_tool_wrapper-$METPLUS_DATA.tgz
	tar -xvzf sample_data-met_tool_wrapper-$METPLUS_DATA.tgz -C $WRF_FOLDER/METplus-$METPLUS_Version/Sample_Data

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

#####################################BASH Script Finished##############################

end=$(date)
END=$(date +"%s")
DIFF=$(($END - $START))
echo "Install Start Time: ${start}"
echo "Install End Time: ${end}"
echo "Install Duration: $(($DIFF / 3600)) hours $((($DIFF % 3600) / 60)) minutes $(($DIFF % 60)) seconds"
