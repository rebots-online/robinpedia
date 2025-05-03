#!/bin/bash
# ========================================================================
# Java Multiple Versions Configuration Script for Robinpedia
# (C)2025 Robin L. M. Cheung, MBA
# ========================================================================
# This script configures multiple Java versions for the project
# - Java 17 for Gradle/Android builds (primary and required for Android compatibility)
# - Java 21 for general development and Neo4j (should not be used for Android builds)
# 
# Usage: ./configure_java_versions.sh
# ========================================================================

echo "====== Robinpedia Java Version Configuration ======"

# Create logs directory if it doesn't exist
mkdir -p logs

# Log file
LOG_FILE="logs/java_config_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Checking installed Java versions..."

# Function to check if a Java version is installed
check_java_version() {
    local version=$1
    local paths=(
        "/usr/lib/jvm/java-$version-openjdk"
        "/usr/lib/jvm/java-$version-openjdk-amd64"
        "/usr/lib/jvm/temurin-$version-jdk"
        "/usr/lib/jvm/adoptopenjdk-$version"
        "/Library/Java/JavaVirtualMachines/temurin-$version.jdk/Contents/Home"
    )
    
    for path in "${paths[@]}"; do
        if [ -d "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Find Java 17
JAVA17_PATH=$(check_java_version "17")
if [ -z "$JAVA17_PATH" ]; then
    echo "Java 17 not found. You may need to install it for Gradle builds."
    echo "You can run ./scripts/build_with_java17.sh which will help you install Java 17."
else
    echo "Found Java 17 at: $JAVA17_PATH"
fi

# Find Java 21
JAVA21_PATH=$(check_java_version "21")
if [ -z "$JAVA21_PATH" ]; then
    echo "Java 21 not found. You should install it for Neo4j and general development."
    echo "You can run ./scripts/setup_java21.sh to install Java 21."
else
    echo "Found Java 21 at: $JAVA21_PATH"
fi

# Create/update VSCode settings
VSCODE_DIR=".vscode"
SETTINGS_FILE="$VSCODE_DIR/settings.json"

if [ ! -d "$VSCODE_DIR" ]; then
    mkdir -p "$VSCODE_DIR"
    echo "Created $VSCODE_DIR directory"
fi

# Generate the settings JSON content
generate_settings() {
    local content="{\n"
    
    # Add Java configuration
    content+="    \"java.configuration.runtimes\": ["
    
    # Add Java 17 if found (preferred for Android builds)
    if [ -n "$JAVA17_PATH" ]; then
        content+="\n        {\n"
        content+="            \"name\": \"JavaSE-17\",\n"
        content+="            \"path\": \"$JAVA17_PATH\",\n"
        content+="            \"default\": true\n"
        content+="        }"
        
        # Add comma if Java 21 is also found
        if [ -n "$JAVA21_PATH" ]; then
            content+=","
        fi
    fi
    
    # Add Java 21 if found
    if [ -n "$JAVA21_PATH" ]; then
        content+="\n        {\n"
        content+="            \"name\": \"JavaSE-21\",\n"
        content+="            \"path\": \"$JAVA21_PATH\"\n"
        content+="        }"
    fi
    
    content+="\n    ]"
    
    # Close the JSON object
    content+="\n}"
    
    echo -e "$content"
}

# Update settings.json
if [ -f "$SETTINGS_FILE" ]; then
    # Backup existing settings
    cp "$SETTINGS_FILE" "$SETTINGS_FILE.bak"
    echo "Backed up existing settings to $SETTINGS_FILE.bak"
    
    # Check if file already has java.configuration.runtimes
    if grep -q "java.configuration.runtimes" "$SETTINGS_FILE"; then
        echo "Updating existing Java configuration in $SETTINGS_FILE"
        # This is a simplification; in reality, you'd want to use a proper JSON parser
        # For now, we'll just replace the file
        generate_settings > "$SETTINGS_FILE"
    else
        # Remove closing brace, add our config, then close it again
        sed '$d' "$SETTINGS_FILE" > "$SETTINGS_FILE.tmp"
        if grep -q "}$" "$SETTINGS_FILE.tmp"; then
            # Add comma if the file doesn't end with a comma
            echo "," >> "$SETTINGS_FILE.tmp"
        fi
        echo "    \"java.configuration.runtimes\": [" >> "$SETTINGS_FILE.tmp"
        
        # Add Java 17 if found (preferred for Android builds)
        if [ -n "$JAVA17_PATH" ]; then
            echo "        {" >> "$SETTINGS_FILE.tmp"
            echo "            \"name\": \"JavaSE-17\"," >> "$SETTINGS_FILE.tmp"
            echo "            \"path\": \"$JAVA17_PATH\"," >> "$SETTINGS_FILE.tmp"
            echo "            \"default\": true" >> "$SETTINGS_FILE.tmp"
            echo "        }" >> "$SETTINGS_FILE.tmp"
            
            # Add comma if Java 21 is also found
            if [ -n "$JAVA21_PATH" ]; then
                echo "        ," >> "$SETTINGS_FILE.tmp"
            fi
        fi
        
        # Add Java 21 if found
        if [ -n "$JAVA21_PATH" ]; then
            echo "        {" >> "$SETTINGS_FILE.tmp"
            echo "            \"name\": \"JavaSE-21\"," >> "$SETTINGS_FILE.tmp"
            echo "            \"path\": \"$JAVA21_PATH\"" >> "$SETTINGS_FILE.tmp"
            echo "        }" >> "$SETTINGS_FILE.tmp"
        fi
        
        echo "    ]" >> "$SETTINGS_FILE.tmp"
        echo "}" >> "$SETTINGS_FILE.tmp"
        
        mv "$SETTINGS_FILE.tmp" "$SETTINGS_FILE"
    fi
else
    echo "Creating new $SETTINGS_FILE with Java configuration"
    generate_settings > "$SETTINGS_FILE"
fi

echo ""
echo "VSCode Java configuration updated successfully"

# Create a helper script to quickly set JAVA_HOME
cat > scripts/use_java21.sh << EOF
#!/bin/bash
# Quick script to set JAVA_HOME to Java 21
export JAVA_HOME="$JAVA21_PATH"
export PATH="\$JAVA_HOME/bin:\$PATH"
echo "JAVA_HOME set to \$JAVA_HOME"
java -version
EOF

cat > scripts/use_java17.sh << EOF
#!/bin/bash
# Quick script to set JAVA_HOME to Java 17
export JAVA_HOME="$JAVA17_PATH"
export PATH="\$JAVA_HOME/bin:\$PATH"
echo "JAVA_HOME set to \$JAVA_HOME"
java -version
EOF

chmod +x scripts/use_java21.sh
chmod +x scripts/use_java17.sh

echo ""
echo "Created helper scripts:"
echo "  - scripts/use_java21.sh: Quickly set JAVA_HOME to Java 21"
echo "  - scripts/use_java17.sh: Quickly set JAVA_HOME to Java 17"
echo ""
echo "To use these scripts in your current terminal session:"
echo "  source scripts/use_java21.sh"
echo "  source scripts/use_java17.sh"
echo ""
echo "For building Android with Java 17, use:"
echo "  ./scripts/build_with_java17.sh"
echo ""
echo "====== Configuration Complete ======"
echo "See $LOG_FILE for details"