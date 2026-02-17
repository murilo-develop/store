#!/bin/bash
set -e

echo "🚀 Setting up local Kamal deployment environment..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Stop and remove old container
echo -e "${YELLOW}Step 1: Cleaning up old container...${NC}"
docker stop simple-ubuntu 2>/dev/null || true
docker rm simple-ubuntu 2>/dev/null || true

# Step 2: Build new image with SSH and Docker
echo -e "${YELLOW}Step 2: Building Ubuntu container with SSH and Docker...${NC}"
docker build -f UbuntuDockerFile -t simple-ubuntu .

# Step 3: Run container with host Docker socket (avoids Docker-in-Docker overlay issues)
# Add host.docker.internal to allow container to reach Mac's localhost
# Mount project directory at SAME path as Mac so Docker volume mounts work
echo -e "${YELLOW}Step 3: Starting container with host Docker socket...${NC}"
PROJECT_DIR="$(pwd)"
echo "Mounting project at: $PROJECT_DIR"

# Create the directory structure in container that matches Mac path
docker run -d \
  --name simple-ubuntu-temp \
  simple-ubuntu \
  sleep 10

docker exec simple-ubuntu-temp sudo mkdir -p "$(dirname "$PROJECT_DIR")"
docker exec simple-ubuntu-temp sudo chown -R apprunner:apprunner "$(dirname "$PROJECT_DIR")"
docker stop simple-ubuntu-temp
docker rm simple-ubuntu-temp

# Now run with the project mounted at same path as Mac
# Note: Port 3000 NOT mapped here - the app container will bind it directly
docker run -d \
  --name simple-ubuntu \
  --add-host=host.docker.internal:host-gateway \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PROJECT_DIR:$PROJECT_DIR" \
  -w "$PROJECT_DIR" \
  -p 2000:22 \
  -p 8181:80 \
  simple-ubuntu

# Wait for container to be ready
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 5

# Fix Docker socket permissions for apprunner user
echo -e "${YELLOW}Configuring Docker socket permissions...${NC}"
docker exec simple-ubuntu sudo chmod 666 /var/run/docker.sock
echo -e "${GREEN}✓ Docker socket accessible${NC}"

# Step 4: Setup SSH key authentication
echo -e "${YELLOW}Step 4: Setting up SSH key authentication...${NC}"

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_kamal_local ]; then
  echo "Generating SSH key..."
  ssh-keygen -t ed25519 -f ~/.ssh/id_kamal_local -N ""
fi

# Copy public key to container and configure to run commands from project directory
echo "Installing public key with command wrapper..."
docker exec simple-ubuntu bash -c "mkdir -p /home/apprunner/.ssh && chmod 700 /home/apprunner/.ssh"

# Create a wrapper script that changes to project directory before running commands
docker exec simple-ubuntu bash -c "cat > /home/apprunner/ssh-wrapper.sh << 'WRAPPER'
#!/bin/bash
cd $PROJECT_DIR
if [ -n \"\$SSH_ORIGINAL_COMMAND\" ]; then
  eval \"\$SSH_ORIGINAL_COMMAND\"
else
  exec bash -l
fi
WRAPPER"

docker exec simple-ubuntu bash -c "chmod +x /home/apprunner/ssh-wrapper.sh && chown apprunner:apprunner /home/apprunner/ssh-wrapper.sh"

# Install public key with forced command that uses the wrapper
PUB_KEY=$(cat ~/.ssh/id_kamal_local.pub)
docker exec simple-ubuntu bash -c "echo 'command=\"PROJECT_DIR=$PROJECT_DIR /home/apprunner/ssh-wrapper.sh\" $PUB_KEY' > /home/apprunner/.ssh/authorized_keys && chmod 600 /home/apprunner/.ssh/authorized_keys && chown -R apprunner:apprunner /home/apprunner/.ssh"

echo -e "${GREEN}✓ SSH configured to run commands from project directory${NC}"

# Step 5: Configure SSH client
echo -e "${YELLOW}Step 5: Configuring SSH client...${NC}"
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -q "Host kamal-local" "$SSH_CONFIG" 2>/dev/null; then
  cat >> "$SSH_CONFIG" << 'EOF'

# Kamal local deployment
Host kamal-local localhost
  HostName localhost
  Port 2000
  User apprunner
  IdentityFile ~/.ssh/id_kamal_local
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF
  echo "SSH config updated"
fi

# Step 6: Test SSH connection
echo -e "${YELLOW}Step 6: Testing SSH connection...${NC}"
if ssh -p 2000 -i ~/.ssh/id_kamal_local -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null apprunner@localhost "echo 'SSH connection successful!'" 2>/dev/null; then
  echo -e "${GREEN}✓ SSH connection working!${NC}"
else
  echo -e "${YELLOW}⚠ SSH connection test failed. Trying to restart SSH service...${NC}"
  docker exec simple-ubuntu sudo service ssh restart
  sleep 2
fi

# Step 7: Verifying Docker in container (uses host Docker socket)
echo -e "${YELLOW}Step 7: Verifying Docker in container...${NC}"
docker exec simple-ubuntu docker --version
echo -e "${GREEN}✓ Docker CLI working (using host Docker daemon)${NC}"

# Step 8: Configure Mac's Docker Desktop for insecure registry
echo -e "${YELLOW}Step 8: Mac Docker Desktop configuration needed...${NC}"
echo -e "${YELLOW}Please add insecure registry to Docker Desktop:${NC}"
echo "  1. Open Docker Desktop"
echo "  2. Go to Settings > Docker Engine"
echo "  3. Add: \"insecure-registries\": [\"localhost:5001\"]"
echo "  4. Click Apply & Restart"
echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "1. Configure Docker Desktop insecure registry (see above)"
echo "2. Verify .kamal/secrets file has RAILS_MASTER_KEY"
echo "3. Run: bin/kamal setup"
echo ""
echo "Architecture:"
echo "  - Container uses HOST Docker socket (-v /var/run/docker.sock)"
echo "  - No Docker-in-Docker = No overlay filesystem issues"
echo "  - Kamal starts kamal-docker-registry on Mac at 127.0.0.1:5001"
echo "  - App built for ARM64 and pushed to localhost:5001"
echo "  - Container pulls from localhost:5001 via host.docker.internal"
echo "  - App runs in container, accessible at localhost:3000"
echo ""
echo "Useful commands:"
echo "  - SSH into container: ssh kamal-local"
echo "  - Check container logs: docker logs simple-ubuntu"
echo "  - View active containers: docker ps"
echo "  - Check Kamal registry: docker logs kamal-docker-registry"
echo "  - View deployment: bin/kamal app containers"
echo "  - App logs: bin/kamal app logs"
