#!/bin/bash
# ========================================================================
# Java 21 Setup Script for Robinpedia
# (C)2025 Robin L. M. Cheung, MBA
# ========================================================================
# This script checks for Java 21 installation and configures the environment
# for Android development with Robinpedia.
# 
# Usage: ./setup_java21.sh
# ========================================================================

echo "====== Robinpedia Java 21 Setup ======"
echo "Checking current Java version..."

# Check if Java is installed
if ! command -v java &> /dev/null; then
    echo "Java is not installed."
    JAVA_INSTALLED=false
else
    JAVA_INSTALLED=true
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    echo "Current Java version: $JAVA_VERSION"
fi

# Check for specific OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    DISTRO=""
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    fi
    
    if [[ "$JAVA_INSTALLED" == "false" || "$JAVA_VERSION" != "21" ]]; then
        echo "Java 21 needs to be installed."
        
        if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
            echo "Detected Ubuntu/Debian: Installing OpenJDK 21..."
            sudo apt update
            sudo apt install -y openjdk-21-jdk
        elif [[ "$DISTRO" == "fedora" ]]; then
            echo "Detected Fedora: Installing OpenJDK 21..."
            sudo dnf install -y java-21-openjdk-devel
        elif [[ "$DISTRO" == "arch" ]]; then
            echo "Detected Arch Linux: Installing JDK 21..."
            sudo pacman -S --noconfirm jdk21-openjdk
        else
            echo "Unsupported Linux distribution. Please install JDK 21 manually."
            exit 1
        fi
    fi
    
    # Find Java 21 installation path
    if command -v update-alternatives &> /dev/null; then
        JAVA_HOME=$(update-alternatives --display java | grep "link currently points to" | awk '{print $5}' | sed 's/\/bin\/java//')
    elif [ -d "/usr/lib/jvm/java-21-openjdk" ]; then
        JAVA_HOME="/usr/lib/jvm/java-21-openjdk"
    elif [ -d "/usr/lib/jvm/java-21-openjdk-amd64" ]; then
        JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
    else
        echo "Could not determine JAVA_HOME. Please set it manually."
        exit 1
    fi
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if [[ "$JAVA_INSTALLED" == "false" || "$JAVA_VERSION" != "21" ]]; then
        echo "Java 21 needs to be installed."
        if command -v brew &> /dev/null; then
            echo "Using Homebrew to install OpenJDK 21..."
            brew install --cask temurin21
        else
            echo "Homebrew not found. Please install it first or manually install JDK 21."
            echo "You can download from: https://www.oracle.com/java/technologies/downloads/#java21"
            exit 1
        fi
    fi
    
    # Find Java Home on macOS
    JAVA_HOME=$(/usr/libexec/java_home -v 21)
    
elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    echo "Windows detected. Please install JDK 21 manually from:"
    echo "https://www.oracle.com/java/technologies/downloads/#java21"
    echo "Then set JAVA_HOME environment variable to your JDK installation path."
    exit 0
else
    echo "Unsupported operating system. Please install JDK 21 manually."
    exit 1
fi

# Verify installation
echo "Verifying Java installation..."
java -version

# Set JAVA_HOME
echo "Setting up JAVA_HOME environment variable to: $JAVA_HOME"

# Update shell config based on which shell is used
SHELL_CONFIG=""
if [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    echo "Could not find .bashrc or .zshrc. Please set JAVA_HOME manually."
    exit 1
fi

# Check if JAVA_HOME is already set in config
if grep -q "export JAVA_HOME=" "$SHELL_CONFIG"; then
    # Update existing JAVA_HOME
    sed -i.bak "s|export JAVA_HOME=.*|export JAVA_HOME=$JAVA_HOME|g" "$SHELL_CONFIG"
else
    # Add JAVA_HOME to config
    echo "" >> "$SHELL_CONFIG"
    echo "# Added by Robinpedia setup script" >> "$SHELL_CONFIG"
    echo "export JAVA_HOME=$JAVA_HOME" >> "$SHELL_CONFIG"
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> "$SHELL_CONFIG"
fi

echo ""
echo "====== Java 21 Setup Complete ======"
echo "JAVA_HOME has been set to: $JAVA_HOME"
echo "Please run 'source $SHELL_CONFIG' or restart your terminal to apply changes."
echo ""
echo "You can now build the Android app with the correct Java version."