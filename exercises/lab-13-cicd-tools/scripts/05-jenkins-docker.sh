#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lab 13 — Script 05: Run Jenkins in Docker
# Starts a Jenkins LTS container and retrieves the initial admin password
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

JENKINS_IMAGE="jenkins/jenkins:lts-jdk17"
CONTAINER_NAME="lab13-jenkins"
JENKINS_PORT=8080
JENKINS_AGENT_PORT=50000
JENKINS_VOLUME="jenkins_home"
JENKINS_URL="http://localhost:${JENKINS_PORT}"

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
# Step 1: Verify Docker is available
# ------------------------------------------------------------------------------
print_header "Step 1: Verify Docker"

if ! command -v docker &>/dev/null; then
    echo "ERROR: Docker is not installed or not in PATH." >&2
    echo "Install Docker: https://docs.docker.com/engine/install/" >&2
    exit 1
fi

if ! docker info &>/dev/null; then
    echo "ERROR: Docker daemon is not running, or current user lacks permission." >&2
    echo "Try: sudo systemctl start docker   (or add user to 'docker' group)" >&2
    exit 1
fi

echo "Docker is available:"
docker --version

# ------------------------------------------------------------------------------
# Step 2: Pull the Jenkins image
# ------------------------------------------------------------------------------
print_header "Step 2: Pull Jenkins Image"

print_step "Image: $JENKINS_IMAGE"
echo "This is the official Jenkins LTS image with Java 17 pre-installed."
echo "Pulling (this may take a few minutes on first run)..."
echo ""
docker pull "$JENKINS_IMAGE"
echo ""
echo "Image pulled successfully."

# ------------------------------------------------------------------------------
# Step 3: Start (or reuse) the Jenkins container
# ------------------------------------------------------------------------------
print_header "Step 3: Start Jenkins Container"

# Check if a container with this name already exists
EXISTING_STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "not_found")

if [ "$EXISTING_STATUS" = "running" ]; then
    echo "Container '$CONTAINER_NAME' is already running — skipping start."

elif [ "$EXISTING_STATUS" = "exited" ] || [ "$EXISTING_STATUS" = "stopped" ]; then
    print_step "Container exists but is stopped — restarting"
    docker start "$CONTAINER_NAME"
    echo "Container restarted."

else
    print_step "Starting new Jenkins container"
    echo "Command:"
    echo "  docker run -d \\"
    echo "    --name $CONTAINER_NAME \\"
    echo "    -p ${JENKINS_PORT}:8080 -p ${JENKINS_AGENT_PORT}:50000 \\"
    echo "    -v ${JENKINS_VOLUME}:/var/jenkins_home \\"
    echo "    $JENKINS_IMAGE"
    echo ""
    docker run -d \
        --name "$CONTAINER_NAME" \
        -p "${JENKINS_PORT}:8080" \
        -p "${JENKINS_AGENT_PORT}:50000" \
        -v "${JENKINS_VOLUME}:/var/jenkins_home" \
        "$JENKINS_IMAGE"
    echo ""
    echo "Container started: $CONTAINER_NAME"
fi

# Show container status
echo ""
echo "Container details:"
docker ps --filter "name=$CONTAINER_NAME" --format "  ID: {{.ID}}\n  Image: {{.Image}}\n  Status: {{.Status}}\n  Ports: {{.Ports}}"

# ------------------------------------------------------------------------------
# Step 4: Wait for Jenkins to be ready
# ------------------------------------------------------------------------------
print_header "Step 4: Wait for Jenkins to Be Ready"

print_step "Polling $JENKINS_URL (up to 60 seconds)"
echo "Jenkins needs time to unpack, initialize plugins, and start the web server."
echo ""

TIMEOUT=60
ELAPSED=0
READY=false

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$JENKINS_URL/login" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "403" ]; then
        READY=true
        break
    fi
    printf "  [%2ds] HTTP %s — waiting...\n" "$ELAPSED" "$HTTP_CODE"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ "$READY" = true ]; then
    echo ""
    echo "Jenkins is ready! (responded with HTTP $HTTP_CODE after ${ELAPSED}s)"
else
    echo ""
    echo "WARNING: Jenkins did not respond within ${TIMEOUT}s."
    echo "It may still be starting. Check container logs:"
    echo "  docker logs $CONTAINER_NAME"
fi

# ------------------------------------------------------------------------------
# Step 5: Retrieve initial admin password
# ------------------------------------------------------------------------------
print_header "Step 5: Initial Admin Password"

print_step "Retrieving password from Jenkins container"
echo "Jenkins generates a one-time setup password on first start."
echo ""

ADMIN_PASSWORD=""
for i in 1 2 3; do
    ADMIN_PASSWORD=$(docker exec "$CONTAINER_NAME" cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || true)
    if [ -n "$ADMIN_PASSWORD" ]; then
        break
    fi
    echo "  Attempt $i: password file not yet written — waiting 5s..."
    sleep 5
done

if [ -n "$ADMIN_PASSWORD" ]; then
    echo ""
    echo "  ┌────────────────────────────────────────────────────────┐"
    echo "  │  INITIAL ADMIN PASSWORD:                               │"
    echo "  │                                                        │"
    printf  "  │  %-54s  │\n" "$ADMIN_PASSWORD"
    echo "  │                                                        │"
    echo "  └────────────────────────────────────────────────────────┘"
else
    echo ""
    echo "WARNING: Could not read the admin password yet."
    echo "Try manually once Jenkins fully starts:"
    echo "  docker exec $CONTAINER_NAME cat /var/jenkins_home/secrets/initialAdminPassword"
fi

# ------------------------------------------------------------------------------
# Step 6: Setup instructions
# ------------------------------------------------------------------------------
print_header "Step 6: Jenkins Setup Instructions"

echo ""
echo "1. Open your browser and go to: $JENKINS_URL"
echo ""
echo "2. Enter the initial admin password shown above."
echo ""
echo "3. On the 'Customize Jenkins' screen choose:"
echo "   - 'Install suggested plugins'  (recommended for beginners)"
echo "   - Or 'Select plugins to install' for custom setup"
echo ""
echo "4. Create your first admin user (or continue as admin)."
echo ""
echo "5. Set the Jenkins URL (default: http://localhost:8080) and click 'Save and Finish'."
echo ""
echo "6. Jenkins is ready to use!"
echo ""
echo "Useful Docker commands:"
printf "  %-48s  %s\n" "docker logs -f $CONTAINER_NAME"        "Stream Jenkins logs"
printf "  %-48s  %s\n" "docker stop $CONTAINER_NAME"           "Stop Jenkins"
printf "  %-48s  %s\n" "docker start $CONTAINER_NAME"          "Restart Jenkins"
printf "  %-48s  %s\n" "docker rm -f $CONTAINER_NAME"          "Remove container (data retained in volume)"
printf "  %-48s  %s\n" "docker volume rm $JENKINS_VOLUME"      "Delete all Jenkins data"

# ------------------------------------------------------------------------------
# Step 7: Sample Jenkinsfile reference
# ------------------------------------------------------------------------------
print_header "Step 7: Sample Jenkinsfile (Pipeline Reference)"

echo ""
echo "A Jenkinsfile defines a CI/CD pipeline as code. Example for this project:"
echo ""
cat <<'JENKINSFILE'
// Declarative Pipeline syntax
pipeline {
    agent any   // Run on any available agent

    tools {
        jdk   'Java17'   // Must be configured in Jenkins > Tools
        maven 'Maven3'   // Must be configured in Jenkins > Tools
    }

    stages {
        stage('Checkout') {
            steps {
                // Check out source code from SCM (e.g., GitHub)
                checkout scm
            }
        }

        stage('Compile') {
            steps {
                sh 'mvn -q compile'
            }
        }

        stage('Test') {
            steps {
                sh 'mvn -q test'
            }
            post {
                always {
                    // Publish JUnit test results
                    junit 'target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn -q package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }

    post {
        success {
            echo 'Build succeeded!'
        }
        failure {
            echo 'Build failed — check the logs above.'
        }
    }
}
JENKINSFILE

echo ""
echo "Save this as 'Jenkinsfile' in the root of your project repository,"
echo "then create a 'Pipeline' job in Jenkins pointing to your SCM."
echo ""
echo "Jenkins setup script complete."
echo ""
