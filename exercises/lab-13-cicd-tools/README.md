# Lab 13: Installation of Git, Gradle, Maven and Jenkins

**Topic:** Setup CI/CD tools and version control — Git, Gradle, Maven, Jenkins

---

## Objectives

By the end of this lab you will be able to:

- Install and verify Git, Java 17, Maven, and Gradle on a Linux system
- Demonstrate core Git workflows: init, commit, branch, merge
- Build, test, and package a Java application using Gradle
- Build, test, and package a Java application using Maven
- Run a Jenkins CI server locally using Docker
- Retrieve the Jenkins initial admin password and complete first-time setup
- Understand the role of each tool in a modern CI/CD pipeline

---

## Background

### What is CI/CD?

**Continuous Integration (CI)** is the practice of automatically building and testing code every time a developer pushes changes. **Continuous Delivery/Deployment (CD)** extends CI by automatically deploying verified builds to staging or production environments.

A typical CI/CD pipeline looks like this:

```
Developer pushes code
        |
        v
  [Git Repository]
        |
        v
  [Jenkins / CI Server]
        |
        +---> Compile (Maven / Gradle)
        |
        +---> Unit Tests
        |
        +---> Static Analysis / Linting
        |
        +---> Package (JAR / WAR / Docker Image)
        |
        +---> Deploy to Staging
        |
        v
  [Production Deployment]
```

### Tool Overview

| Tool | Category | Purpose |
|------|----------|---------|
| **Git** | Version Control | Track source code changes; enable collaboration via branches and merges |
| **Maven** | Build Tool | Convention-based Java build and dependency management via `pom.xml` |
| **Gradle** | Build Tool | Script-based Java/Android build tool with incremental builds via `build.gradle` |
| **Jenkins** | CI/CD Server | Automation server that orchestrates build, test, and deploy pipelines |

---

## Tool Comparison Tables

### Git vs SVN (Subversion)

| Aspect | Git | SVN |
|--------|-----|-----|
| Architecture | Distributed (every clone is full repo) | Centralized (single server) |
| Branching | Lightweight, fast | Heavy, slow |
| Offline work | Full capability | Limited |
| History | Local and complete | Requires server access |
| Merge strategy | Three-way merge, rebasing | Two-way merge |
| Adoption | Industry standard | Legacy enterprise systems |
| Hosting | GitHub, GitLab, Bitbucket | Apache SVN, Assembla |

### Maven vs Gradle

| Aspect | Maven | Gradle |
|--------|-------|--------|
| Build file | `pom.xml` (XML) | `build.gradle` (Groovy or Kotlin DSL) |
| Configuration style | Convention over configuration | Code-based, flexible |
| Performance | Standard | Incremental builds, build cache, parallel execution |
| Android support | No | Official Android build tool |
| Learning curve | Gentle (XML) | Steeper (scripting knowledge) |
| Plugin ecosystem | Rich (Apache Maven Central) | Rich (Gradle Plugin Portal) |
| Multi-project builds | Modules via parent POM | Multi-project builds via `settings.gradle` |

### Jenkins vs GitHub Actions

| Aspect | Jenkins | GitHub Actions |
|--------|---------|---------------|
| Hosting | Self-hosted (on-prem or cloud) | Hosted by GitHub (SaaS) |
| Setup | Manual install + configuration | Zero setup for GitHub repos |
| Pipeline definition | `Jenkinsfile` (Groovy DSL) | `.github/workflows/*.yml` (YAML) |
| Plugin ecosystem | 1800+ plugins | Marketplace actions |
| Cost | Free (infrastructure cost only) | Free tier; paid for large usage |
| Flexibility | Very high | High within GitHub ecosystem |
| Best for | Enterprise, on-prem requirements | Open source, GitHub-hosted projects |

---

## Git Workflow Diagram

```
  Working Tree         Staging Area          Local Repo          Remote Repo
  (your files)         (git index)           (.git/)             (GitHub/GitLab)
       |                    |                    |                     |
       |-- git add -------->|                    |                     |
       |                    |-- git commit ----->|                     |
       |                    |                    |-- git push -------->|
       |<-- git checkout ---|<------------------ |                     |
       |                    |                    |<-- git fetch -------|
       |<-----------------------------------------git pull ------------|
       |                    |                    |                     |
```

**Key concepts:**

- **Working Tree** — the files you see and edit on disk
- **Staging Area (Index)** — a draft of your next commit; selectively add changes with `git add`
- **Local Repository** — the full version history stored in `.git/`
- **Remote Repository** — the shared copy hosted on a server (GitHub, GitLab, Bitbucket)

---

## Maven Build Lifecycle

Maven defines three built-in lifecycles. The **default** lifecycle is used for project builds:

| Phase | Order | Description |
|-------|-------|-------------|
| `validate` | 1 | Validate the project structure and POM correctness |
| `compile` | 2 | Compile `src/main/java` into `target/classes` |
| `test` | 3 | Compile and run unit tests from `src/test/java` |
| `package` | 4 | Bundle compiled classes into a JAR or WAR in `target/` |
| `verify` | 5 | Run integration tests and quality gate checks |
| `install` | 6 | Install the artifact to the local `~/.m2` repository |
| `deploy` | 7 | Upload the artifact to a remote Maven repository |

> Running any phase automatically executes all preceding phases.
> Example: `mvn package` runs validate → compile → test → package.

---

## Gradle Build Lifecycle

Gradle organizes work into three phases:

| Phase | Description |
|-------|-------------|
| **Initialization** | Determines which projects are part of the build (reads `settings.gradle`) |
| **Configuration** | Evaluates all `build.gradle` scripts and constructs the task dependency graph |
| **Execution** | Runs the requested tasks and their dependencies in the correct order |

**Common Gradle tasks for this project:**

| Task | Command | Description |
|------|---------|-------------|
| Compile | `gradle compileJava` | Compile main source files |
| Test | `gradle test` | Run unit tests |
| Package | `gradle jar` | Build the JAR artifact |
| Run | `gradle run` | Execute the main class |
| Clean | `gradle clean` | Delete the `build/` directory |
| Full build | `gradle build` | Compile + test + package |
| Dependencies | `gradle dependencies` | Print the dependency tree |

---

## Jenkins Pipeline Stages Concept

A Jenkins **Declarative Pipeline** (Jenkinsfile) describes CI/CD steps as code:

```
Checkout --> Compile --> Test --> Package --> Deploy
   |            |          |         |           |
  scm          mvn        mvn      mvn jar    kubectl /
 checkout     compile    test    package      SSH / etc.
```

**Core Jenkinsfile structure:**

```groovy
pipeline {
    agent any
    stages {
        stage('Checkout') { steps { checkout scm } }
        stage('Compile')  { steps { sh 'mvn compile' } }
        stage('Test')     { steps { sh 'mvn test' } }
        stage('Package')  { steps { sh 'mvn package -DskipTests' } }
        stage('Deploy')   { steps { sh './deploy.sh' } }
    }
    post {
        success { echo 'Pipeline succeeded' }
        failure { echo 'Pipeline failed' }
    }
}
```

---

## Sample Project

The `sample-project/` directory contains a minimal Java application demonstrating both build tools:

```
sample-project/
├── build.gradle          Gradle build script
├── settings.gradle       Gradle project name
├── pom.xml               Maven project descriptor
└── src/
    ├── main/java/com/lab13/App.java       Main application class
    └── test/java/com/lab13/AppTest.java   JUnit 5 unit test
```

The app exposes a single `App.greet(String name)` method and a `main()` entry point.

---

## Scripts

Run each script in order to complete the lab exercises.

### 01 — Install Tools
```bash
bash scripts/01-install-tools.sh
```
Installs Java 17, Maven, and Gradle (with apt fallback for Gradle). Prints a summary version table when done.

### 02 — Git Workflow Demo
```bash
bash scripts/02-git-demo.sh
```
Creates a temporary Git repository and walks through: init, config, add, commit, branch, checkout, merge, and log graph. Cleans up the temp directory on exit.

### 03 — Gradle Build
```bash
bash scripts/03-gradle-build.sh
```
Runs from `sample-project/`. Demonstrates: dependency resolution, compile, test, jar packaging, and running the app via `gradle run`.

### 04 — Maven Build
```bash
bash scripts/04-maven-build.sh
```
Runs from `sample-project/`. Demonstrates: compile, test, package, and running the app directly via `java -cp`.

### 05 — Jenkins in Docker
```bash
bash scripts/05-jenkins-docker.sh
```
Pulls `jenkins/jenkins:lts-jdk17`, starts it as a Docker container on port 8080, waits for it to be ready, and prints the initial admin password. Includes a sample Jenkinsfile reference.

### cleanup — Remove All Lab Resources
```bash
bash scripts/cleanup.sh
```
Stops and removes the Jenkins container and volume. Deletes `build/` and `target/` from the sample project. Source files are untouched.

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Linux (Ubuntu/Debian) | Scripts use `apt-get` |
| `sudo` access | Required by `01-install-tools.sh` |
| Docker | Required by `05-jenkins-docker.sh` |
| Internet access | For downloading packages and Docker images |

---

## Devcontainer Note

If you are working inside the provided development container, Java 17, Maven, and Gradle may already be available via devcontainer features configured in `.devcontainer/`. In that case, `01-install-tools.sh` will detect the existing installations and skip them — it is safe to run regardless.

After a devcontainer rebuild, all tools will be re-provisioned automatically by the container feature definitions.

---

## Expected Outcomes

After completing all scripts you will have:

1. All four CI/CD tools installed and verified
2. A Git repository with branching and merging demonstrated
3. A JAR artifact built by Gradle in `sample-project/build/libs/`
4. A JAR artifact built by Maven in `sample-project/target/`
5. Jenkins running at `http://localhost:8080` and ready for first-time setup
6. Understanding of how each tool fits into a real CI/CD pipeline
