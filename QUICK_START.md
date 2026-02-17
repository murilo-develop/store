# Quick Start Guide: Kamal Local Deployment

## ✅ Setup Complete!

Your environment is now configured to deploy your Rails app to your local Ubuntu container using Kamal.

## 📋 What Was Configured

### Files Created/Modified:
1. **UbuntuDockerFile** - Updated with SSH and Docker CLI (uses host socket)
2. **config/deploy.yml** - Configured for local deployment with ARM64 architecture
3. **.kamal/ssh_config** - SSH connection settings
4. **.kamal/secrets** - Rails master key configuration
5. **setup-kamal-local.sh** - Automated setup script with path mounting
6. **KAMAL_LOCAL_SETUP.md** - Detailed documentation

### Container Details:
- **Name**: simple-ubuntu  
- **SSH Port**: 2000 (on host)
- **Port 80**: 8181 (on host)
- **Port 3000**: 3000 (on host)
- **User**: apprunner
- **SSH Key**: ~/.ssh/id_kamal_local

### Registry Configuration:
- **Kamal-Managed**: kamal-docker-registry started automatically by Kamal
- **Location**: Mac at 127.0.0.1:5001
- **Container Access**: Uses host Docker daemon via socket mount
- **Insecure Registry**: Must be configured on Mac's Docker Desktop
- **Architecture**: ARM64 (Apple Silicon)

### Key Architecture Notes:
- **No Docker-in-Docker**: Container uses host's Docker daemon via socket
- **Path Mounting**: Project mounted at same path as Mac for volume compatibility
- **SSH Wrapper**: Forces all commands to run from project directory
- **No Overlay Issues**: Host Docker avoids filesystem limitations

## 🚀 Deploy Your App

Now you can run Kamal commands:

```bash
# First time setup (installs dependencies, sets up volumes, etc.)
bin/kamal setup

# Or just deploy
bin/kamal deploy

# View logs
bin/kamal app logs -f

# Access Rails console
bin/kamal console

# SSH into the container
bin/kamal app exec -i bash
# or directly:
ssh -p 2000 -i ~/.ssh/id_kamal_local apprunner@localhost
```

## 🔍 Verify Connection

Test that Kamal can connect to your container:

```bash
# Test configuration
bin/kamal config

# Test SSH connection
bin/kamal server bootstrap

# Or manually:
ssh -p 2000 -i ~/.ssh/id_kamal_local apprunner@localhost "docker ps"
```

## 📦 Access Your Deployed App

Once deployed, your app will be accessible at:
- **Application**: http://localhost:3000

## 🛠️ Troubleshooting

### If Kamal can't connect:
```bash
# Restart the container
docker restart simple-ubuntu

# Check SSH is running
docker exec simple-ubuntu service ssh status

# Check Docker is running in container
docker exec simple-ubuntu docker ps

# Test SSH manually
ssh -p 2000 -i ~/.ssh/id_kamal_local apprunner@localhost
```

### If deployment fails:
```bash
# Check Kamal logs
bin/kamal app logs

# Remove and start fresh
bin/kamal remove
bin/kamal setup

# Check container logs
docker logs simple-ubuntu
```

### If the container stops:
```bash
# Restart it
docker start simple-ubuntu

# Or rebuild everything
./setup-kamal-local.sh
```

## 📝 Key Configuration Details

### deploy.yml settings:
- **Server**: localhost (connects via SSH on port 2000)
- **SSH User**: apprunner
- **SSH Port**: 2000
- **Registry**: localhost:5001 (runs on your Mac)
- **Image**: store
- **Service**: store

### How It Works:
1. Kamal connects to simple-ubuntu container via SSH (port 2000)
2. simple-ubuntu is just an SSH gateway - uses host Docker via socket
3. Registry runs on your Mac at localhost:5001
4. Builds your Rails app image on your Mac for ARM64
5. Pushes the image to the registry (localhost:5001)
6. App container runs on Mac Docker (not inside simple-ubuntu)
7. Port 3000 published directly from app container to Mac
8. Access app at http://localhost:3000

### Active Containers:
- **simple-ubuntu**: SSH gateway to reach Mac Docker
- **kamal-docker-registry**: Docker registry on your Mac (localhost:5001)
- **buildx_buildkit_***: Builder container for multi-platform builds
- **kamal-proxy**: HTTP proxy routing (port 80 → 8181 on Mac)
- **store-web-***: Your Rails application (port 3000 on Mac)

All containers except simple-ubuntu run directly on Mac Docker, not nested.

## 🎯 Next Steps

1. **Run your first deployment**:
   ```bash
   bin/kamal setup
   ```
   This will:
   - Build your Rails app image
   - Push the image to the registry at localhost:5001 on your Mac
   - Deploy to the Ubuntu container (pulls from localhost:5001)

2. **Check the deployment**:
   ```bash
   bin/kamal app containers
   bin/kamal app logs
   ```

3. **Access your app**:
   Open http://localhost:3000 in your browser

4. **Make changes and redeploy**:
   ```bash
   # Make code changes, then:
   bin/kamal deploy
   ```

## ⚠️ Important Notes

- This setup is for **local development/learning** only
- Don't use Docker-in-Docker for production
- The container must be running for deployments to work
- Images are built on your Mac, then pushed to the local registry

### Active Containers Required:
- **simple-ubuntu**: Your deployment target (must be running)
- **local-registry**: Registry on your Mac at localhost:5001 (must be running)
- **buildx_buildkit_***: Build container (auto-started)

### Cleaning Up
To remove all Kamal deployments:
```bash
bin/kamal remove
```

To clean up old Docker resources:
```bash
docker system prune -f
```

## 📚 Additional Resources

- See `KAMAL_LOCAL_SETUP.md` for detailed documentation
- Kamal docs: https://kamal-deploy.org
- Run `bin/kamal help` for all commands

## 🎉 You're Ready!

Everything is configured. Just run:
```bash
bin/kamal setup
```

And watch your app deploy! 🚀
