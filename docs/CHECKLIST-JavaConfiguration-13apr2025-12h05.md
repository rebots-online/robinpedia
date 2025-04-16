# Java Configuration Checklist - 13 April 2025

## Objective
Configure Java 21 and Java 17 according to RedHat requirements to ensure proper operation of Gradle and Java extensions.

## Reference
- [RedHat Java Requirements Documentation](https://github.com/redhat-developer/vscode-java/wiki/JDK-Requirements#java.configuration.runtimes)

## Tasks

✅ **Java 21 Installation Detection**
- [X] Verified Temurin Java 21 is installed at `/usr/lib/jvm/temurin-21-jdk-amd64`
- [X] Updated scripts to properly detect the Temurin JDK installation paths

✅ **Java 17 Configuration for Gradle**
- [X] Verified Java 17 is available at `/usr/lib/jvm/java-17-openjdk-amd64`
- [X] Configured Gradle to use Java 17 through VS Code settings

✅ **VS Code Configuration**
- [X] Updated global and project-specific VS Code settings
- [X] Added proper `java.configuration.runtimes` settings
- [X] Configured Java 21 as default with fallback to Java 17 for specific operations

✅ **Helper Scripts Updates**
- [X] Updated `use_java21.sh` to properly detect and use Temurin Java 21
- [X] Updated `use_java17.sh` to properly detect and use OpenJDK Java 17
- [X] Improved detection mechanisms in `configure_java_versions_global.sh`

## Notes
- Both Java versions are now properly configured in VS Code
- Global settings have been applied for consistent behavior across workspaces
- Helper scripts are available for quickly switching Java versions in terminal sessions:
  - `source ./scripts/use_java21.sh` for Java 21
  - `source ./scripts/use_java17.sh` for Java 17

## Results
- Java 21 (Temurin) is the default for general development
- Java 17 is configured for Gradle/Android builds
- Configuration is in line with RedHat's recommendations for multi-JDK projects