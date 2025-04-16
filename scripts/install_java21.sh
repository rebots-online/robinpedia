#!/bin/bash
# ========================================================================
# Install Java 21 (Temurin/Adoptium JDK)
# (C)2025 Robin L. M. Cheung, MBA
# ========================================================================
# This script installs Java 21 from the Adoptium/Temurin project,
# which is the recommended distribution for Neo4j and modern Java apps.
# ========================================================================

# Echo with color
echo_green() {
  echo -e "\e[32m$1\e[0m"
}

echo_yellow() {
  echo -e "\e[33m$1\e[0m"
}

echo_red() {
  echo -e "\e[31m$1\e[0m"
}

# Detect OS
detect_os() {
  case "$(uname -s)" in
    Linux*)     echo "linux";;
    Darwin*)    echo "macos";;
    CYGWIN*)    echo "windows";;
    MINGW*)     echo "windows";;
    MSYS*)      echo "windows";;
    *)          echo "unknown";;
  esac
}

# Check if running as root (for Linux only)
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo_red "This script must be run as root on Linux. Please use sudo."
    exit 1
  fi
}

# Main script
echo_green "========================================================"
echo_green "             Installing Java 21 (Temurin)               "
echo_green "========================================================"

# Detect OS
os=$(detect_os)
echo "Detected OS: $os"

case "$os" in
  linux)
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
      echo_yellow "This script must be run as root on Linux. Attempting to use sudo..."
      echo_yellow "If prompted, please enter your password."
      exec sudo "$0"
      exit $?
    fi
    
    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      distro="$ID"
    elif [ -f /etc/lsb-release ]; then
      . /etc/lsb-release
      distro="$DISTRIB_ID"
    else
      distro="unknown"
    fi
    
    echo "Detected Linux distribution: $distro"
    
    # Install Java 21 based on distribution
    case "$distro" in
      ubuntu|debian|pop|mint|elementary)
        echo "Installing Adoptium repository..."
        apt-get update
        apt-get install -y wget apt-transport-https gnupg
        
        # Add Adoptium repository
        mkdir -p /etc/apt/keyrings
        wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | tee /etc/apt/keyrings/adoptium.asc
        echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
        
        apt-get update
        apt-get install -y temurin-21-jdk
        ;;
        
      fedora|rhel|centos|rocky|alma)
        echo "Installing Adoptium repository..."
        dnf install -y curl
        
        # Add Adoptium repository
        curl -L https://packages.adoptium.net/artifactory/rpm/rhel/$(rpm -E %rhel)/$(arch)/Adoptium.repo > /etc/yum.repos.d/Adoptium.repo
        
        dnf install -y temurin-21-jdk
        ;;
        
      arch|manjaro)
        echo "Installing Java 21 from Arch repositories..."
        pacman -Sy --noconfirm jdk-openjdk
        ;;
        
      opensuse|suse)
        echo "Installing Java 21 from openSUSE repositories..."
        zypper install -y java-21-openjdk java-21-openjdk-devel
        ;;
        
      *)
        echo_yellow "Unsupported Linux distribution: $distro"
        echo_yellow "Attempting to install using SDKMAN..."
        
        # Try SDKMAN as a fallback
        if ! command -v sdk &> /dev/null; then
          echo "Installing SDKMAN..."
          apt-get update || dnf check-update || zypper refresh || pacman -Sy
          apt-get install -y curl zip unzip || dnf install -y curl zip unzip || zypper install -y curl zip unzip || pacman -S --noconfirm curl zip unzip
          
          curl -s "https://get.sdkman.io" | bash
          source "$HOME/.sdkman/bin/sdkman-init.sh"
        fi
        
        sdk install java 21.0.2-tem
        ;;
    esac
    ;;
    
  macos)
    # Install Homebrew if not already installed
    if ! command -v brew &> /dev/null; then
      echo "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install Java 21 using Homebrew
    echo "Installing Java 21 using Homebrew..."
    brew install --cask temurin21
    ;;
    
  windows)
    echo_yellow "For Windows, please install Java 21 manually:"
    echo_yellow "1. Visit https://adoptium.net/temurin/releases/?version=21"
    echo_yellow "2. Download and run the Windows installer (.msi file)"
    echo_yellow "3. Follow the installation wizard instructions"
    ;;
    
  *)
    echo_red "Unsupported OS: $os"
    exit 1
    ;;
esac

# Verify installation
if [ "$os" != "windows" ]; then
  echo_green "Verifying Java 21 installation..."
  
  # Update path for this session
  export PATH="/usr/lib/jvm/temurin-21-jdk/bin:$PATH"
  
  if java -version 2>&1 | grep -q "version \"21"; then
    echo_green "Java 21 installed successfully!"
    java -version
  else
    echo_yellow "Java installation completed, but unable to verify version."
    echo_yellow "Please run 'java -version' in a new terminal to verify."
  fi
fi

echo_green "========================================================"
echo_green "Java 21 installation completed!"
echo_green "========================================================"
echo ""
echo "Next steps:"
echo "1. Run './scripts/configure_java_versions_global.sh' to configure VSCode"
echo "2. Restart VSCode for the changes to take effect"
echo ""
echo_green "========================================================"