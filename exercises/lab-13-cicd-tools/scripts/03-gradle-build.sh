#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lab 13 — Script 03: Build with Gradle
# Demonstrates compiling, testing, packaging, and running a Java app via Gradle
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../sample-project"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
print_header() {
    echo ""
    echo "============================================================"
    echo "  $1"
    echo "============================================================"
}

print_step() {
    echo ""
    echo "--- $1 ---"
}

# ------------------------------------------------------------------------------
# Pre-flight: verify Gradle is available
# ------------------------------------------------------------------------------
print_header "Pre-flight Check"

if ! command -v gradle &>/dev/null; then
    echo "ERROR: gradle is not installed. Run scripts/01-install-tools.sh first." >&2
    exit 1
fi

if ! command -v java &>/dev/null; then
    echo "ERROR: java is not installed. Run scripts/01-install-tools.sh first." >&2
    exit 1
fi

echo "Gradle: $(gradle --version 2>&1 | grep '^Gradle' | head -1)"
echo "Java:   $(java -version 2>&1 | head -1)"
echo "Project directory: $PROJECT_DIR"

cd "$PROJECT_DIR"

# ------------------------------------------------------------------------------
# Step 1: Show build.gradle
# ------------------------------------------------------------------------------
print_header "Step 1: build.gradle Contents"

print_step "The build script defines plugins, dependencies, and tasks"
echo ""
cat build.gradle

# ------------------------------------------------------------------------------
# Step 2: Dependency tree
# ------------------------------------------------------------------------------
print_header "Step 2: Dependency Tree"

print_step "Command: gradle --no-daemon dependencies --configuration testRuntimeClasspath"
echo "This shows the resolved dependency graph for the test runtime."
echo "The --no-daemon flag skips the Gradle daemon (useful in CI environments)."
echo ""
gradle --no-daemon dependencies --configuration testRuntimeClasspath 2>&1 | head -50
echo ""
echo "(Output truncated to 50 lines for readability)"

# ------------------------------------------------------------------------------
# Step 3: Compile
# ------------------------------------------------------------------------------
print_header "Step 3: Compile Java Sources"

print_step "Command: gradle --no-daemon compileJava"
echo "Compiles src/main/java/** to build/classes/."
echo ""
gradle --no-daemon compileJava
echo ""
echo "Compiled class files:"
find build/classes -name "*.class" 2>/dev/null || echo "  (no .class files found — check for errors above)"

# ------------------------------------------------------------------------------
# Step 4: Run unit tests
# ------------------------------------------------------------------------------
print_header "Step 4: Run Unit Tests"

print_step "Command: gradle --no-daemon test"
echo "Executes tests under src/test/java/** using the JUnit Jupiter platform."
echo ""
gradle --no-daemon test
echo ""
echo "Test report written to: build/reports/tests/test/index.html"

# ------------------------------------------------------------------------------
# Step 5: Build the JAR
# ------------------------------------------------------------------------------
print_header "Step 5: Package as JAR"

print_step "Command: gradle --no-daemon jar"
echo "Bundles compiled classes into a .jar archive in build/libs/."
echo ""
gradle --no-daemon jar
echo ""
echo "JAR artifact:"
find build/libs -name "*.jar" 2>/dev/null | while read -r jar; do
    echo "  $jar  ($(du -sh "$jar" | cut -f1))"
done

# ------------------------------------------------------------------------------
# Step 6: Run the application
# ------------------------------------------------------------------------------
print_header "Step 6: Run the Application"

print_step "Command: gradle --no-daemon run"
echo "Invokes the main class defined in build.gradle: application { mainClass = 'com.lab13.App' }"
echo ""
gradle --no-daemon run

# ------------------------------------------------------------------------------
# Gradle vs Maven comparison
# ------------------------------------------------------------------------------
print_header "Gradle vs Maven Comparison"

echo ""
printf "  %-24s  %-34s  %-34s\n" "ASPECT" "GRADLE" "MAVEN"
printf "  %-24s  %-34s  %-34s\n" "------------------------" "----------------------------------" "----------------------------------"
printf "  %-24s  %-34s  %-34s\n" "Build file"       "build.gradle (Groovy/Kotlin DSL)" "pom.xml (XML)"
printf "  %-24s  %-34s  %-34s\n" "Configuration"    "Script / code"                   "Convention / declaration"
printf "  %-24s  %-34s  %-34s\n" "Performance"      "Incremental builds, build cache"  "Slower for large projects"
printf "  %-24s  %-34s  %-34s\n" "Extensibility"    "Custom tasks via Groovy/Kotlin"   "Plugins via XML configuration"
printf "  %-24s  %-34s  %-34s\n" "Ecosystem"        "Android, Spring, multi-project"   "Dominant in enterprise Java"
printf "  %-24s  %-34s  %-34s\n" "Learning curve"   "Steeper (scripting knowledge)"    "Gentler (XML familiarity)"
printf "  %-24s  %-34s  %-34s\n" "Dependency mgmt"  "Flexible (configs)"               "Standard scopes"
printf "  %-24s  %-34s  %-34s\n" "Wrapper"          "gradlew (Gradle Wrapper)"         "mvnw (Maven Wrapper)"

echo ""
echo "Gradle build complete."
echo ""
