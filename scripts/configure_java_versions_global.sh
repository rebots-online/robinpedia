#!/bin/bash
# ========================================================================
# Configure Java Versions Globally for VSCode
# (C)2025 Robin L. M. Cheung, MBA
# ========================================================================
# This script configures VSCode to use multiple Java versions globally,
# setting Java 21 as the default and Java 17 for Gradle/Android builds.
# The configuration applies to all VSCode projects system-wide.
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

# Get VSCode global settings path
get_vscode_settings_path() {
  local os=$1
  
  case "$os" in
    linux)
      echo "$HOME/.config/Code/User/settings.json"
      ;;
    macos)
      echo "$HOME/Library/Application Support/Code/User/settings.json"
      ;;
    windows)
      if [ -n "$APPDATA" ]; then
        echo "$APPDATA/Code/User/settings.json"
      else
        echo "$HOME/AppData/Roaming/Code/User/settings.json"
      fi
      ;;
    *)
      echo_red "Unsupported OS: $os"
      return 1
      ;;
  esac
}

# Detect Java installations
detect_java_installations() {
  local detected=()
  local os=$(detect_os)
  
  # Common paths for Linux
  if [ "$os" = "linux" ]; then
    local linux_paths=(
      "/usr/lib/jvm/java-21-openjdk"
      "/usr/lib/jvm/java-21-openjdk-amd64"
      "/usr/lib/jvm/temurin-21-jdk"
      "/usr/lib/jvm/temurin-21-jdk-amd64"
      "/usr/lib/jvm/java-17-openjdk"
      "/usr/lib/jvm/java-17-openjdk-amd64"
      "/usr/lib/jvm/temurin-17-jdk"
      "/usr/lib/jvm/temurin-17-jdk-amd64"
    )
    
    for path in "${linux_paths[@]}"; do
      if [ -d "$path" ]; then
        version=$(basename "$path" | grep -oE '[0-9]+' | head -1)
        detected+=("JavaSE-$version:$path")
      fi
    done
    
    # Try update-alternatives for Linux
    if command -v update-alternatives &> /dev/null; then
      for version in 21 17; do
        # Try to find both OpenJDK and Temurin paths using update-alternatives
        java_paths=$(update-alternatives --list java 2>/dev/null | grep -E "java-$version|temurin-$version" | sed 's|/bin/java||')
        if [ -n "$java_paths" ]; then
          while IFS= read -r java_path; do
            if [ -d "$java_path" ]; then
              detected+=("JavaSE-$version:$java_path")
            fi
          done <<< "$java_paths"
        fi
      done
    fi
  fi
  
  # Common paths for macOS
  if [ "$os" = "macos" ]; then
    local macos_paths=(
      "/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home"
      "/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
      "/Library/Java/JavaVirtualMachines/openjdk-21.jdk/Contents/Home"
      "/Library/Java/JavaVirtualMachines/openjdk-17.jdk/Contents/Home"
    )
    
    for path in "${macos_paths[@]}"; do
      if [ -d "$path" ]; then
        version=$(basename "$path" | grep -oE '[0-9]+' | head -1)
        if [ -z "$version" ]; then
          # Try to extract from parent directory name
          version=$(basename "$(dirname "$path")" | grep -oE '[0-9]+' | head -1)
        fi
        detected+=("JavaSE-$version:$path")
      fi
    done
  fi
  
  # Common paths for Windows
  if [ "$os" = "windows" ]; then
    local win_paths=(
      "/c/Program Files/Eclipse Adoptium/jdk-21.0.1.12-hotspot"
      "/c/Program Files/Eclipse Adoptium/jdk-17.0.9.9-hotspot"
      "/c/Program Files/Java/jdk-21"
      "/c/Program Files/Java/jdk-17"
    )
    
    for path in "${win_paths[@]}"; do
      if [ -d "$path" ]; then
        version=$(basename "$path" | grep -oE '[0-9]+' | head -1)
        detected+=("JavaSE-$version:$path")
      fi
    done
  fi
  
  # If no JDKs found, try JAVA_HOME
  if [ ${#detected[@]} -eq 0 ] && [ -n "$JAVA_HOME" ] && [ -d "$JAVA_HOME" ]; then
    # Try to determine version from JAVA_HOME
    if [ -x "$JAVA_HOME/bin/java" ]; then
      version=$("$JAVA_HOME/bin/java" -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
      if [ -n "$version" ]; then
        detected+=("JavaSE-$version:$JAVA_HOME")
      fi
    fi
  fi
  
  # Return the detected installations
  for installation in "${detected[@]}"; do
    echo "$installation"
  done
}

# Update or create global VSCode settings
update_vscode_settings() {
  local settings_path=$1
  local java21_path=$2
  local java17_path=$3
  
  # Create settings directory if it doesn't exist
  mkdir -p "$(dirname "$settings_path")"
  
  # Create backup of settings if it exists
  if [ -f "$settings_path" ]; then
    cp "$settings_path" "${settings_path}.backup.$(date +%Y%m%d%H%M%S)"
    echo_yellow "Backup of existing settings created at ${settings_path}.backup.$(date +%Y%m%d%H%M%S)"
  else
    # Create empty settings file if it doesn't exist
    echo "{}" > "$settings_path"
  fi
  
  # Load existing settings or create new ones
  local temp_file=$(mktemp)
  if [ -s "$settings_path" ]; then
    cat "$settings_path" > "$temp_file"
  else
    echo "{}" > "$temp_file"
  fi
  
  # Check if the file is valid JSON
  if ! command -v jq &> /dev/null; then
    echo_yellow "jq not installed, using manual JSON editing"
    
    # Remove trailing }
    sed -i 's/}$//' "$temp_file"
    
    # Add comma if needed
    if [ "$(tail -c 2 "$temp_file")" != "," ] && [ "$(tail -c 2 "$temp_file")" != "{" ]; then
      echo "," >> "$temp_file"
    fi
    
    # Add Java settings
    cat << EOF >> "$temp_file"
  "java.configuration.runtimes": [
    {
      "name": "JavaSE-21",
      "path": "$java21_path",
      "default": true
    },
    {
      "name": "JavaSE-17",
      "path": "$java17_path"
    }
  ],
  "java.jdt.ls.java.home": "$java21_path",
  "java.import.gradle.java.home": "$java17_path",
  "java.configuration.updateBuildConfiguration": "automatic"
}
EOF
  else
    # Get existing settings
    jq_filter='.["java.configuration.runtimes"] = [
      {"name": "JavaSE-21", "path": "'"$java21_path"'", "default": true},
      {"name": "JavaSE-17", "path": "'"$java17_path"'"}
    ] | .["java.jdt.ls.java.home"] = "'"$java21_path"'" | .["java.import.gradle.java.home"] = "'"$java17_path"'" | .["java.configuration.updateBuildConfiguration"] = "automatic"'
    
    jq "$jq_filter" "$temp_file" > "${temp_file}.new"
    mv "${temp_file}.new" "$temp_file"
  fi
  
  # Write updated settings back
  cat "$temp_file" > "$settings_path"
  rm "$temp_file"
  
  echo_green "VSCode settings updated at $settings_path"
}

# Update project-specific settings
update_project_settings() {
  local java21_path=$1
  local java17_path=$2
  
  local project_settings=".vscode/settings.json"
  
  # Create .vscode directory if it doesn't exist
  mkdir -p ".vscode"
  
  # Create backup of settings if it exists
  if [ -f "$project_settings" ]; then
    cp "$project_settings" "${project_settings}.backup.$(date +%Y%m%d%H%M%S)"
    echo_yellow "Backup of project settings created at ${project_settings}.backup.$(date +%Y%m%d%H%M%S)"
  fi
  
  # Create project settings file
  cat << EOF > "$project_settings"
{
    // Java configuration for multiple JDK support
    "java.configuration.runtimes": [
        {
            "name": "JavaSE-21",
            "path": "$java21_path",
            "default": true
        },
        {
            "name": "JavaSE-17",
            "path": "$java17_path"
        }
    ],
    
    // Java settings that help with mixed version projects
    "java.jdt.ls.java.home": "$java21_path",
    "java.import.gradle.java.home": "$java17_path",
    "java.configuration.updateBuildConfiguration": "automatic",
    
    // Recommended Java extension settings
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
EOF
  
  echo_green "Project settings updated at $project_settings"
}

# Main script
echo_green "========================================================"
echo_green "     Configuring Java Versions Globally for VSCode      "
echo_green "========================================================"

# Detect OS
os=$(detect_os)
echo "Detected OS: $os"

# Get VSCode settings path
settings_path=$(get_vscode_settings_path "$os")
echo "VSCode settings path: $settings_path"

# Detect Java installations
echo "Detecting Java installations..."
installations=$(detect_java_installations)

if [ -z "$installations" ]; then
  echo_red "No Java installations detected. Please install JDK 21 and JDK 17."
  exit 1
fi

# Filter installations for Java 21 and 17
java21_path=""
java17_path=""

while IFS= read -r installation; do
  name=$(echo "$installation" | cut -d':' -f1)
  path=$(echo "$installation" | cut -d':' -f2-)
  
  if [ "$name" = "JavaSE-21" ]; then
    java21_path="$path"
    echo "Found JDK 21: $path"
  elif [ "$name" = "JavaSE-17" ]; then
    java17_path="$path"
    echo "Found JDK 17: $path"
  fi
done <<< "$installations"

# Check if Java installations were found
if [ -z "$java21_path" ] && [ -z "$java17_path" ]; then
  echo_red "No Java installations found. Please install JDK 21 or JDK 17."
  exit 1
fi

# If Java 21 was found but Java 17 wasn't
if [ -n "$java21_path" ] && [ -z "$java17_path" ]; then
  echo_yellow "Java 21 found, but Java 17 not found. Using Java 21 for all operations."
  java17_path="$java21_path"
fi

# If Java 17 was found but Java 21 wasn't
if [ -z "$java21_path" ] && [ -n "$java17_path" ]; then
  echo_yellow "Java 17 found, but Java 21 not found. Using Java 17 for all operations."
  echo_yellow "Consider installing Java 21 for optimal Neo4j performance."
  java21_path="$java17_path"
fi

# Update VSCode settings
echo "Updating global VSCode settings..."
update_vscode_settings "$settings_path" "$java21_path" "$java17_path"

# Update project settings
echo "Updating project-specific settings as fallback..."
update_project_settings "$java21_path" "$java17_path"

# Make helper scripts executable
chmod +x scripts/use_java21.sh scripts/use_java17.sh

echo_green "========================================================"
echo_green "Configuration complete!"
echo_green "========================================================"
echo ""
if [ "$java21_path" = "$java17_path" ]; then
  if [ -n "$java21_path" ]; then
    echo "VSCode is now configured to use Java 21 for all operations"
    echo "Use 'source ./scripts/use_java21.sh' to ensure Java 21 is active in a terminal session"
  else
    echo "VSCode is now configured to use Java 17 for all operations"
    echo "Use 'source ./scripts/use_java17.sh' to ensure Java 17 is active in a terminal session"
  fi
else
  echo "VSCode will now use Java 21 by default, with Java 17 for Gradle/Android builds"
  echo "Use 'source ./scripts/use_java21.sh' to switch to Java 21 in a terminal session"
  echo "Use 'source ./scripts/use_java17.sh' to switch to Java 17 in a terminal session"
fi
echo_green "========================================================"