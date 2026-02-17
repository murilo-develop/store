# Kamal Local Deployment Setup Guide

This guide explains how to deploy your Rails app using Kamal to a local Ubuntu Docker container.

## Prerequisites

- Docker installed on your macOS
- SSH client (comes with macOS)
- Your Rails app with Kamal configured

## Setup Steps

### 1. Run the Automated Setup Script

The easiest way to get everything configured is to run the setup script:

```bash
./setup-kamal-local.sh
```

This script will:
- Build a new Ubuntu container with SSH and Docker CLI installed
- Start the container with host Docker socket mounted (no Docker-in-Docker)
- Mount project directory at same path for volume compatibility
- Generate SSH keys for secure authentication
- Configure SSH wrapper to run commands from project directory
- Configure your SSH client
- Test the connection

### 2. Verify the Setup

After running the script, verify everything is working:

```bash
# Test SSH connection
ssh kamal-local

# Inside the container, check Docker
docker --version

# Exit the container
exit
```

### 3. Deploy with Kamal

Now you can use Kamal to deploy:

```bash
# First time setup - builds and deploys your app
bin/kamal setup

# Or if already set up, just deploy
bin/kamal deploy
```

### 4. Access Your Application

Your app will be available at:
- **Application**: http://localhost:3000

The container also exposes:
- **SSH**: localhost:2000
- **Port 80**: localhost:8181

## Configuration Files Changed

### deploy.yml
- Server changed to `localhost` (with SSH port 2000 configured)
- SSH user set to `apprunner`
- Registry configuration: `localhost:5001` (automatically managed by Kamal)
- Builder: ARM64 architecture (for Apple Silicon Macs)
- Credentials: Username "local", password "dummy" (required by Kamal)

### UbuntuDockerFile
- Added OpenSSH server
- Added Docker CLI only (uses host Docker daemon via socket)
- Creates docker group for socket access
- Added startup script to run SSH service
- No Docker daemon (avoids overlay filesystem issues)

### Registry
- **Kamal-managed**: Kamal automatically starts kamal-docker-registry
- **Location**: Mac at 127.0.0.1:5001 (localhost only)
- **Access from Ubuntu**: Via host Docker socket (container uses host daemon)
- **Insecure registry**: Must be configured in Mac's Docker Desktop settings
- **No daemon in container**: Ubuntu container only has Docker CLI

## Architecture Overview

Here's how all the components work together:

```
┌─────────────────────────────────────────────────────┐
│ Your Mac (Host)                                     │
│                                                     │
│  ┌──────────────────────┐    ┌──────────────────┐   │
│  │ kamal-docker-registry│    │ Docker Daemon    │   │
│  │ 127.0.0.1:5001       │◄───┤ /var/run/        │   │
│  └──────────────────────┘    │ docker.sock      │   │
│                              └────────┬─────────┘   │
│  ┌────────────────────────────────────┼─────────┐   │
│  │ simple-ubuntu Container            │         │   │
│  │                                    │         │   │
│  │  - Mounts: docker.sock ────────────┘         │   │
│  │  - Mounts: project at Mac's path             │   │
│  │  - SSH wrapper forces PWD = project path     │   │
│  │  - Docker CLI uses host daemon               │   │
│  │  - No overlay filesystem issues              │   │
│  └──────────────────────────────────────────────┘   │
│     │                                               │
│     └──SSH──────────────────────┐                   │
│                                 ▼                   │
│  ┌────────────────────────────────────────────┐     │
│  │ simple-ubuntu container (SSH gateway)      │     │
│  │                                            │     │
│  │  • SSH server on port 22 → Mac:2000        │     │
│  │  • Docker CLI (uses host daemon)           │     │
│  │  • Project mounted at Mac's path           │     │
│  │  • Port 8181 → 80 (for kamal-proxy)        │     │
│  └────────────────────────────────────────────┘     │
│                                                     │
│  ┌────────────────────────────────────────────┐     │
│  │ store-web container (on Mac Docker)        │     │
│  │                                            │     │
│  │  • Runs Rails app                          │     │
│  │  • Port 3000 → Mac:3000                    │     │
│  │  • Uses host network via simple-ubuntu     │     │
│  └────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────┘
```

### Deployment Flow:
1. **Registry Start**: Kamal starts kamal-docker-registry on Mac at 127.0.0.1:5001
2. **Build Phase**: Rails app image built using Docker buildx for linux/arm64
3. **Push**: Image pushed to localhost:5001 (the Kamal registry)
4. **SSH Deploy**: Kamal SSH's into simple-ubuntu container (port 2000)
5. **Pull**: Container uses host Docker daemon via socket - no pull needed
6. **Deploy**: App container starts on Mac Docker with port 3000 published
7. **Access**: App available at http://localhost:3000

## Troubleshooting

### SSH Connection Failed

```bash
# Restart the container
docker restart simple-ubuntu

# Check if SSH is running
docker exec simple-ubuntu service ssh status

# Restart SSH if needed
docker exec simple-ubuntu sudo service ssh restart
```

### Docker Not Running in Container

```bash
# Verify Docker CLI is accessible
ssh -p 2000 -i ~/.ssh/id_kamal_local apprunner@localhost 'docker --version'

# Check socket permissions
docker exec simple-ubuntu ls -la /var/run/docker.sock

# Fix permissions if needed
docker exec simple-ubuntu sudo chmod 666 /var/run/docker.sock
```
# Check Docker status
docker exec simple-ubuntu docker ps

# Start Docker service
docker exec simple-ubuntu sudo service docker start
```

### Kamal Can't Connect

```bash
# Test SSH manually
ssh -p 2000 -i ~/.ssh/id_kamal_local apprunner@localhost

# Check container logs
docker logs simple-ubuntu

# Verify the container is running
docker ps | grep simple-ubuntu
```

### Build Issues

```bash
# Check if master.key exists
cat config/master.key

# Verify secrets are configured
bin/kamal secrets

# Check deploy configuration
bin/kamal config
```

### Registry Issues

If you see registry connection or authentication errors:
```bash
# Check if local-registry is running on your Mac
docker ps | grep local-registry

# Restart the registry if needed
docker restart local-registry

# Check registry logs
docker logs local-registry

# Verify registry is accessible
curl http://localhost:5001/v2/_catalog
```

**Note**: The registry MUST run on your Mac, not inside the Ubuntu container, due to Docker-in-Docker overlay filesystem limitations.

### Clean Slate

To start fresh:
```bash
# Remove all Kamal-related containers
bin/kamal remove

# Restart the Ubuntu container
docker restart simple-ubuntu

# Run setup again
bin/kamal setup
```

## Manual Commands

If you prefer to set things up manually:

### Build and Start Container

```bash
# Build the image
docker build -f UbuntuDockerFile -t simple-ubuntu .

# Run with privileged mode (needed for Docker-in-Docker)
docker run -d \
  --name simple-ubuntu \
  --privileged \
  -p 2000:22 \
  -p 8181:80 \
  -p 3000:3000 \
  simple-ubuntu

# Start the registry on your Mac
docker run -d -p 5001:5000 --restart=always --name local-registry registry:2
```

### Setup SSH Keys

```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/id_kamal_local -N ""

# Copy to container
docker cp ~/.ssh/id_kamal_local.pub simple-ubuntu:/tmp/key.pub
docker exec simple-ubuntu bash -c "mkdir -p /home/apprunner/.ssh && cat /tmp/key.pub >> /home/apprunner/.ssh/authorized_keys && chmod 600 /home/apprunner/.ssh/authorized_keys && chown -R apprunner:apprunner /home/apprunner/.ssh"
```

## Useful Kamal Commands

```bash
# See all containers on the server
bin/kamal app containers

# View logs
bin/kamal app logs

# Access Rails console
bin/kamal console

# Execute shell in container
bin/kamal shell

# Stop the application
bin/kamal app stop

# Remove everything (clean slate)
bin/kamal remove
```

## Understanding the Setup

### Why Docker-in-Docker?

Kamal deploys by SSH-ing into a server and running Docker commands. Since your "server" is itself a Docker container, we need Docker running inside it (Docker-in-Docker). This requires:
- `--privileged` flag when running the container
- Docker installed inside the container
- Docker service started inside the container

### SSH Key Authentication

Kamal uses SSH to connect to servers. We set up:
- SSH server running in the container on port 22 (mapped to host port 2000)
- SSH key pair for passwordless authentication
- SSH config to use the correct port and key

### Docker Registry

Kamal requires a registry to push/pull images:
- **Manual setup**: Registry runs on your Mac at localhost:5001
- **Why on Mac**: Docker-in-Docker has overlay filesystem limitations that prevent registry containers from running inside privileged containers
- **No authentication needed**: Uses localhost communication
- **Port 5001**: Registry accessible at localhost:5001 on your Mac
- **Auto-started**: The setup script automatically starts the registry

The build process:
1. Build image on your Mac using buildx
2. Push to registry at localhost:5001 (on your Mac)
3. Kamal SSH's into Ubuntu container and tells it to pull from localhost:5001 (which resolves to your Mac's IP)
4. Deploy the pulled image inside the Ubuntu container

## Next Steps

1. Customize your `deploy.yml` for your needs
2. Add accessories (Redis, PostgreSQL, etc.) if needed
3. Set up environment variables in `deploy.yml`
4. Configure SSL if deploying for real use

## Production Considerations

⚠️ **This setup is for LOCAL DEVELOPMENT/LEARNING only!**

For production deployment:
- Use a real server (not Docker-in-Docker)
- Use proper SSH key management
- Use a container registry (Docker Hub, GitHub Container Registry, etc.)
- Set up proper SSL/TLS
- Configure firewall rules
- Use environment-specific secrets management
