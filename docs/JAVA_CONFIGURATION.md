# Java Configuration for Robinpedia

## Overview

Robinpedia requires specific Java configurations to ensure compatibility between:
- VSCode Java extension requirements (Java 21+)
- Gradle build compatibility (Java 17 preferred)

This document explains how these configurations are set up and how to verify them.

## Configuration Requirements

### VSCode Java Extension

The RedHat Java extension for VSCode (as shown in the error message) requires Java 21 or newer to run properly. This is needed for:
- Language server (java.jdt.ls)
- Code completion
- Navigation
- Debugging

### Gradle Build System

While the VSCode extension requires Java 21, our Gradle builds are optimized for Java 17 to ensure maximum compatibility with libraries and dependencies.

## How it Works

Our configuration follows the [RedHat recommendation](https://github.com/redhat-developer/vscode-java/wiki/JDK-Requirements#java.configuration.runtimes) by using the `java.configuration.runtimes` setting to define multiple Java runtimes.

### Key Settings in `.vscode/settings.json`

```json
{
    // Required Java configuration for running VSCode Java extension
    "java.jdt.ls.java.home": "/usr/lib/jvm/temurin-21-jdk-amd64",
    
    // Configure multiple Java runtimes
    "java.configuration.runtimes": [
        {
            "name": "JavaSE-21",
            "path": "/usr/lib/jvm/temurin-21-jdk-amd64",
            "default": true
        },
        {
            "name": "JavaSE-17",
            "path": "/usr/lib/jvm/java-17-openjdk-amd64"
        }
    ],
    
    // Use Java 17 for Gradle to ensure compatibility
    "java.import.gradle.java.home": "/usr/lib/jvm/java-17-openjdk-amd64"
}
```

This configuration:
1. Uses Java 21 for the VS Code Java extension language server
2. Defines both JDK 21 and JDK 17 as available runtimes
3. Configures Gradle to use JDK 17 for project builds

## Installation & Verification

### Required Java Installations

- **Java 21**: Temurin JDK 21 at `/usr/lib/jvm/temurin-21-jdk-amd64`
- **Java 17**: OpenJDK 17 at `/usr/lib/jvm/java-17-openjdk-amd64`

### Verification Script

We provide a script to verify and fix Java configurations:

```bash
./scripts/verify_java_config.sh
```

This script:
- Checks if Java 21 and Java 17 are installed
- Verifies or creates the proper VSCode settings
- Provides guidance on next steps

## Troubleshooting

If you still see the Java 21 extension error in VSCode:

1. Run the verification script: `./scripts/verify_java_config.sh`
2. Reload VSCode window: Press `Ctrl+Shift+P` and select "Developer: Reload Window"
3. Verify the Java extension is using the correct JDK by checking in the Output panel (View > Output) and selecting "Java Language Server" from the dropdown

## Running Gradle with the Correct Java Version

For command-line builds, you can explicitly set the Java home for Gradle:

```bash
./gradlew build -Dorg.gradle.java.home=/usr/lib/jvm/java-17-openjdk-amd64
```

## Further Resources

- [RedHat Java Extension JDK Requirements](https://github.com/redhat-developer/vscode-java/wiki/JDK-Requirements)
- [Gradle Java Compatibility](https://docs.gradle.org/current/userguide/compatibility.html)