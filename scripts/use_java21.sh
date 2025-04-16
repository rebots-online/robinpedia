#!/bin/bash
# ========================================================================
# Switch to Java 21 for the current terminal session
# (C)2025 Robin L. M. Cheung, MBA
# ========================================================================
# Usage: source ./scripts/use_java21.sh
# 
# NOTE: This script must be sourced, not executed, to modify your 
# current shell environment.
# ========================================================================

# Detect Java 21 installation
detect_java21() {
    local paths=(
        "/usr/lib/jvm/java-21-openjdk"
        "/usr/lib/jvm/java-21-openjdk-amd64"
        "/usr/lib/jvm/temurin-21-jdk"
        "/usr/lib/jvm/temurin-21-jdk-amd64"
    )
    
    for path in "${paths[@]}"; do
        if [ -d "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    # If none of the standard paths work, try the alternatives system
    if command -v update-alternatives &> /dev/null; then
        # Try both Java 21 and Temurin 21 patterns
        java_path=$(update-alternatives --list java 2>/dev/null | grep -E 'java-21|temurin-21' | head -1 | sed 's|/bin/java||')
        if [ -n "$java_path" ]; then
            echo "$java_path"
            return 0
        fi
    fi
    
    return 1
}

# Main script
echo "Switching to Java 21..."

JAVA21_HOME=$(detect_java21)

if [ -z "$JAVA21_HOME" ]; then
    echo "Java 21 not found. Please install it first."
    echo "You can run: sudo ./scripts/install_java21.sh"
    return 1
fi

# Update environment variables
export JAVA_HOME="$JAVA21_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

# Verify the switch
echo "Current Java version:"
java -version

echo ""
echo "JAVA_HOME is now set to: $JAVA_HOME"
echo ""
echo "Java 21 is now active for this terminal session."