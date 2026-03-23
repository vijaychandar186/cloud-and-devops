#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lab 13 — Script 04: Build with Maven
# Demonstrates compiling, testing, packaging, and running a Java app via Maven
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
# Pre-flight: verify Maven and Java are available
# ------------------------------------------------------------------------------
print_header "Pre-flight Check"

if ! command -v mvn &>/dev/null; then
    echo "ERROR: mvn is not installed. Run scripts/01-install-tools.sh first." >&2
    exit 1
fi

if ! command -v java &>/dev/null; then
    echo "ERROR: java is not installed. Run scripts/01-install-tools.sh first." >&2
    exit 1
fi

echo "Maven: $(mvn --version 2>&1 | head -1)"
echo "Java:  $(java -version 2>&1 | head -1)"
echo "Project directory: $PROJECT_DIR"

cd "$PROJECT_DIR"

# ------------------------------------------------------------------------------
# Step 1: Show key pom.xml sections
# ------------------------------------------------------------------------------
print_header "Step 1: pom.xml Overview"

print_step "The Project Object Model (POM) is the fundamental unit of Maven configuration"
echo ""
echo "Key sections from pom.xml:"
echo ""
echo "  <groupId>    : com.lab13         — organization identifier"
echo "  <artifactId> : lab13-app         — project/module name"
echo "  <version>    : 1.0.0             — build version"
echo "  <packaging>  : jar               — output artifact type"
echo ""
echo "Full pom.xml:"
echo ""
cat pom.xml

# ------------------------------------------------------------------------------
# Step 2: Compile
# ------------------------------------------------------------------------------
print_header "Step 2: Compile Java Sources"

print_step "Command: mvn -q compile"
echo "The 'compile' lifecycle phase processes src/main/java/** into target/classes/."
echo "The -q flag suppresses Maven's verbose INFO logging."
echo ""
mvn -q compile
echo ""
echo "Compiled class files:"
find target/classes -name "*.class" 2>/dev/null | head -10 || echo "  (no .class files found — check for errors above)"

# ------------------------------------------------------------------------------
# Step 3: Run tests
# ------------------------------------------------------------------------------
print_header "Step 3: Run Unit Tests"

print_step "Command: mvn -q test"
echo "The 'test' phase compiles test sources and runs them via maven-surefire-plugin."
echo "JUnit Jupiter tests are discovered automatically."
echo ""
mvn -q test
echo ""
echo "Surefire test reports written to: target/surefire-reports/"
if [ -d target/surefire-reports ]; then
    ls target/surefire-reports/
fi

# ------------------------------------------------------------------------------
# Step 4: Package
# ------------------------------------------------------------------------------
print_header "Step 4: Package as JAR"

print_step "Command: mvn -q package -DskipTests"
echo "The 'package' phase compiles, tests (skipped here), and bundles the JAR."
echo "-DskipTests skips test execution (tests were already run in step 3)."
echo ""
mvn -q package -DskipTests
echo ""
echo "JAR artifact:"
find target -name "*.jar" -not -name "*sources*" 2>/dev/null | while read -r jar; do
    echo "  $jar  ($(du -sh "$jar" | cut -f1))"
done

# ------------------------------------------------------------------------------
# Step 5: Find and display the JAR
# ------------------------------------------------------------------------------
print_header "Step 5: Locate the Built Artifact"

print_step "Maven places output in target/ by convention"
JAR_PATH=$(find target -name "*.jar" -not -name "*sources*" | head -1)

if [ -z "$JAR_PATH" ]; then
    echo "ERROR: No JAR found in target/. Build may have failed." >&2
    exit 1
fi

echo "Found JAR: $JAR_PATH"
echo ""
echo "JAR contents (first 20 entries):"
jar tf "$JAR_PATH" 2>/dev/null | head -20 || true

# ------------------------------------------------------------------------------
# Step 6: Run the application
# ------------------------------------------------------------------------------
print_header "Step 6: Run the Application"

print_step "Command: java -cp <jar> com.lab13.App"
echo "Runs the main class directly from the packaged JAR using the java CLI."
echo ""
java -cp "$JAR_PATH" com.lab13.App

# ------------------------------------------------------------------------------
# Maven lifecycle reference
# ------------------------------------------------------------------------------
print_header "Maven Build Lifecycle Reference"

echo ""
printf "  %-12s  %-8s  %s\n" "PHASE" "ORDER" "DESCRIPTION"
printf "  %-12s  %-8s  %s\n" "------------" "-------" "------------------------------------------------------"
printf "  %-12s  %-8s  %s\n" "validate"  "1" "Validate project structure and POM correctness"
printf "  %-12s  %-8s  %s\n" "compile"   "2" "Compile src/main/java into target/classes"
printf "  %-12s  %-8s  %s\n" "test"      "3" "Compile and run src/test/java unit tests"
printf "  %-12s  %-8s  %s\n" "package"   "4" "Bundle classes into JAR/WAR in target/"
printf "  %-12s  %-8s  %s\n" "verify"    "5" "Run integration tests and quality checks"
printf "  %-12s  %-8s  %s\n" "install"   "6" "Install artifact to local ~/.m2 repository"
printf "  %-12s  %-8s  %s\n" "deploy"    "7" "Upload artifact to remote Maven repository"

echo ""
echo "Note: Each phase runs all preceding phases automatically."
echo "Example: 'mvn package' runs validate -> compile -> test -> package"
echo ""
echo "Common flags:"
printf "  %-25s  %s\n" "-DskipTests"          "Skip test execution (still compiles tests)"
printf "  %-25s  %s\n" "-Dmaven.test.skip"    "Skip test compilation and execution"
printf "  %-25s  %s\n" "-q / --quiet"         "Suppress INFO log output"
printf "  %-25s  %s\n" "-X / --debug"         "Enable full debug logging"
printf "  %-25s  %s\n" "-pl <module>"         "Build only specified sub-module"
printf "  %-25s  %s\n" "-am"                  "Also build modules the target depends on"

echo ""
echo "Maven build complete."
echo ""
