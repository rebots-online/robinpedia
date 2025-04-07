# Android Build Java Compatibility Fix

## Problem

The Android build was failing with the error:
```
Unsupported class file major version 61
```

This indicated that the JDK executing the Gradle build didn't support Java 17 bytecode, which was required by the project.

## Root Cause

- Our project explicitly requires Java 17 in app/build.gradle
- The Gradle process is using an older JDK version 
- The VSCode Java extension tooling script was compiled with Java 17 but being executed with an older JDK

## Implemented Solution

We upgraded the project to use Java 21 (the latest LTS version) rather than Java 17:

1. Updated app/build.gradle:
   ```gradle
   compileOptions {
       sourceCompatibility JavaVersion.VERSION_21
       targetCompatibility JavaVersion.VERSION_21
   }

   kotlinOptions {
       jvmTarget = '21'
   }
   ```

2. This configuration now requires JDK 21 to be installed on the development system.

3. Created an automated setup script to simplify Java 21 installation:
   ```bash
   # Run the automated setup script
   ./scripts/setup_java21.sh
   ```
   This script detects your OS, installs JDK 21, and configures JAVA_HOME automatically.

## Why Java 21?

- **Latest LTS Release**: Java 21 is the latest Long-Term Support release, ensuring better forward compatibility
- **Enhanced Features**: Provides newer language features and performance improvements
- **Extended Support**: Will have longer support lifecycle than Java 17
- **Bytecode Compatibility**: Code compiled with Java 21 can run on Java 21+ runtime environments

## Solution Options

### Option 1: Use Automated Setup (Recommended)

Run the provided setup script:
```bash
./scripts/setup_java21.sh
```

### Option 2: Update JAVA_HOME Manually

1. Verify your current Java version:
   ```bash
   java -version
   ```

2. Install JDK 17 if not already installed:
   ```bash
   # Ubuntu/Debian
   sudo apt install openjdk-21-jdk
   
   # Arch Linux
   sudo pacman -S jdk21-openjdk
   
   # Fedora
   sudo dnf install java-21-openjdk-devel
   ```

3. Set JAVA_HOME environment variable to JDK 21:
   ```bash
   # Temporary (current terminal session)
   export JAVA_HOME=/path/to/jdk-21
   
   # Permanent (add to ~/.bashrc or ~/.zshrc)
   echo 'export JAVA_HOME=/path/to/jdk-21' >> ~/.bashrc
   echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
   source ~/.bashrc
   ```

4. Verify that JDK 21 is now being used:
   ```bash
   java -version
   ```

### Option 3: Configure Project-Specific JDK

You can configure Gradle to use a specific JDK for this project without changing your system-wide JAVA_HOME:

1. Create or edit `gradle.properties` in the root project directory:
   ```properties
   org.gradle.java.home=/path/to/jdk-21
   ```

### Option 4: Use Gradle JDK Toolchain

1. Update your `app/build.gradle` file (we've already made similar changes):
   ```gradle
   android {
       // Existing configurations...
       
       compileOptions {
           sourceCompatibility JavaVersion.VERSION_21
           targetCompatibility JavaVersion.VERSION_21
       }
       
       // Add this block to explicitly define toolchain
       java {
           toolchain {
               languageVersion = JavaLanguageVersion.of(21)
           }
       }
   }
   ```

### Option 5: Configure VSCode Java Extension

1. In VSCode, go to Settings
2. Search for "java.jdt.ls.java.home" 
3. Set it to the path of your JDK 21 installation

## Verification

After implementing any of these solutions, rebuild your Android project:

```bash
cd /path/to/your/flutter/project
flutter clean
flutter pub get
flutter build apk --debug
```

If the build succeeds, the Java compatibility issue has been resolved.

## Additional Notes

- Remember that all developers working on this project will need JDK 21 installed
- This change may affect CI/CD pipelines which should be updated to use JDK 21
- The Android Gradle Plugin 8.3.0 is fully compatible with Java 21

© 2025 Robin L. M. Cheung, MBA