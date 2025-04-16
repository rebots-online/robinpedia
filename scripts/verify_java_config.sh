#!/bin/bash
# Script to verify Java configuration and ensure VSCode Java extension works properly

set -e

# Define color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Paths to JDKs on the system
JDK21_PATH="/usr/lib/jvm/temurin-21-jdk-amd64"
JDK17_PATH="/usr/lib/jvm/java-17-openjdk-amd64"

echo -e "${BLUE}Robinpedia Java Configuration Verification${NC}"
echo "======================================"

# Check if JDK 21 is installed
if [ -d "$JDK21_PATH" ]; then
    echo -e "${GREEN}✓ Java 21 (Temurin) is installed at $JDK21_PATH${NC}"
    JDK21_VERSION=$("$JDK21_PATH/bin/java" -version 2>&1 | head -n 1)
    echo "  Version: $JDK21_VERSION"
else
    echo -e "${RED}✗ Java 21 (Temurin) is NOT installed at $JDK21_PATH${NC}"
    echo "  Please install Java 21 for VSCode Java extension to work correctly."
    echo "  You can run: sudo apt install temurin-21-jdk"
    exit 1
fi

# Check if JDK 17 is installed
if [ -d "$JDK17_PATH" ]; then
    echo -e "${GREEN}✓ Java 17 (OpenJDK) is installed at $JDK17_PATH${NC}"
    JDK17_VERSION=$("$JDK17_PATH/bin/java" -version 2>&1 | head -n 1)
    echo "  Version: $JDK17_VERSION"
else
    echo -e "${YELLOW}! Java 17 (OpenJDK) is NOT installed at $JDK17_PATH${NC}"
    echo "  This may be needed for Gradle compatibility."
    echo "  You can run: sudo apt install openjdk-17-jdk"
fi

# Create .vscode directory if it doesn't exist
if [ ! -d ".vscode" ]; then
    echo -e "${BLUE}Creating .vscode directory...${NC}"
    mkdir .vscode
fi

# Check if settings.json exists with the correct configuration
SETTINGS_FILE=".vscode/settings.json"
SETTINGS_UPDATED=false

if [ ! -f "$SETTINGS_FILE" ] || ! grep -q "java.configuration.runtimes" "$SETTINGS_FILE"; then
    echo -e "${BLUE}Creating/updating VSCode Java configuration in $SETTINGS_FILE...${NC}"
    
    # Create or update the settings.json file
    cat > "$SETTINGS_FILE" << EOL
{
    // Required Java configuration for running VSCode Java extension
    "java.jdt.ls.java.home": "$JDK21_PATH",
    
    // Configure multiple Java runtimes as per RedHat documentation
    "java.configuration.runtimes": [
        {
            "name": "JavaSE-21",
            "path": "$JDK21_PATH",
            "default": true
        },
        {
            "name": "JavaSE-17",
            "path": "$JDK17_PATH"
        }
    ],
    
    // Use Java 17 for Gradle to ensure compatibility
    "java.import.gradle.java.home": "$JDK17_PATH",
    
    // Additional helpful settings
    "java.configuration.updateBuildConfiguration": "automatic",
    "java.completion.importOrder": [
        "java",
        "javax",
        "org",
        "com"
    ],
    "java.cleanup.actionsOnSave": [
        "qualifyMembers",
        "addOverride"
    ],
    "java.format.settings.url": "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml",
    "java.format.settings.profile": "GoogleStyle"
}
EOL
    SETTINGS_UPDATED=true
    echo -e "${GREEN}✓ VSCode Java configuration updated${NC}"
else
    echo -e "${GREEN}✓ VSCode Java configuration already exists${NC}"
fi

# Final instructions
echo ""
echo -e "${BLUE}Final Steps:${NC}"
if [ "$SETTINGS_UPDATED" = true ]; then
    echo "1. Reload the VSCode window (Ctrl+Shift+P > 'Reload Window')"
    echo "2. The Java extension should now use Java 21 for language features"
    echo "3. Gradle builds will use Java 17 for compatibility"
fi
echo "4. Run Gradle tasks with the Java 17 runtime using:"
echo "   ./gradlew build -Dorg.gradle.java.home=$JDK17_PATH"
echo ""
echo -e "${GREEN}Java configuration verified and setup complete!${NC}"