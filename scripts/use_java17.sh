#!/bin/bash
# ========================================================================
# Switch to Java 17 for the current terminal session (for Android builds)
# (C)2025 Robin L. M. Cheung, MBA
# ========================================================================
# Usage: source ./scripts/use_java17.sh
# 
# NOTE: This script must be sourced, not executed, to modify your 
# current shell environment.
# ========================================================================

# Detect Java 17 installation
detect_java17() {
    local paths=(
        "/usr/lib/jvm/java-17-openjdk"
        "/usr/lib/jvm/java-17-openjdk-amd64"
        "/usr/lib/jvm/temurin-17-jdk"
        "/usr/lib/jvm/temurin-17-jdk-amd64"
    )
    
    for path in "${paths[@]}"; do
        if [ -d "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    # If none of the standard paths work, try the alternatives system
    if command -v update-alternatives &> /dev/null; then
        # Try both Java 17 and Temurin 17 patterns
        java_path=$(update-alternatives --list java 2>/dev/null | grep -E 'java-17|temurin-17' | head -1 | sed 's|/bin/java||')
        if [ -n "$java_path" ]; then
            echo "$java_path"
            return 0
        fi
    fi
    
    return 1
}

# Main script
echo "Switching to Java 17 for Android builds..."

JAVA17_HOME=$(detect_java17)

if [ -z "$JAVA17_HOME" ]; then
    echo "Java 17 not found. Please install it first."
    echo "You can run: sudo ./scripts/build_with_java17.sh"
    return 1
fi

# Update environment variables
export JAVA_HOME="$JAVA17_HOME"
export PATH="$JAVA_HOME/bin:$PATH"

# Verify the switch
echo "Current Java version:"
java -version

echo ""
echo "JAVA_HOME is now set to: $JAVA_HOME"
echo ""
echo "Java 17 is now active for this terminal session."