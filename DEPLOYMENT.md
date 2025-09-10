# HorizCoin Web Demo Deployment Guide

This document provides instructions for setting up automated deployment of the HorizCoin web demo.

## Quick Setup

### Option 1: Deploy to Render (Recommended)

1. **Fork this repository** to your GitHub account

2. **Connect to Render:**
   - Go to [render.com](https://render.com) and sign up/login with GitHub
   - Click "New +" → "Web Service"
   - Connect your forked repository
   - Render will automatically detect the `render.yaml` configuration

3. **Deploy:**
   - Click "Create Web Service"
   - Your app will be available at `https://your-service-name.onrender.com`
   - Deployments happen automatically on pushes to main branch

### Option 2: Deploy to Railway

1. **Fork this repository** to your GitHub account

2. **Set up Railway:**
   - Go to [railway.app](https://railway.app) and sign up/login with GitHub
   - Create a new project from your GitHub repository
   - Railway will use the `railway.toml` configuration

3. **Configure GitHub Actions (Optional):**
   - In your GitHub repository, go to Settings → Secrets and variables → Actions
   - Add the following secrets:
     - `RAILWAY_TOKEN`: Your Railway API token (from Railway dashboard)
     - `RAILWAY_SERVICE_ID`: Your service ID (optional, defaults to 'horizcoin-web')

4. **Deploy:**
   - Push to main branch to trigger deployment
   - Your app will be available at your Railway URL

## Configuration Files

### render.yaml
```yaml
services:
  - type: web
    name: horizcoin-web
    runtime: docker
    dockerfilePath: ./Dockerfile
    healthCheckPath: /healthz
    plan: free
    region: oregon
    env: web
    autoDeploy: true
    envVars:
      - key: PORT
        value: 10000
```

### railway.toml
```toml
[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"

[deploy]
startCommand = "horizcoin-web"
healthcheckPath = "/healthz"
healthcheckTimeout = 30
restartPolicyType = "on_failure"
restartPolicyMaxRetries = 3
```

## GitHub Actions Workflow

The `.github/workflows/deploy.yml` workflow:

1. **Tests** the web application before deployment
2. **Deploys to Railway** if `RAILWAY_TOKEN` secret is configured
3. **Supports Render** automatic deployment via GitHub integration

## Endpoints

Once deployed, your application will provide:

- `/` - Main page with HorizCoin information
- `/healthz` - Health check endpoint (returns "ok")

## Troubleshooting

### Docker Build Issues
If you encounter SSL certificate issues during Docker build, this is typically an environment-specific problem. The deployment should still work on the cloud platforms.

### Health Check Failures
Ensure your deployment platform is configured to use the `/healthz` endpoint for health checks.

### Port Configuration
- Render uses port 10000 by default
- Railway detects the port automatically
- Local development uses port 3000

## Support

For deployment issues:
- Check the platform-specific logs (Render dashboard or Railway logs)
- Ensure the health check endpoint is responding
- Verify the Docker build completes successfully

## Example URLs

After deployment, your application will be accessible at URLs like:
- Render: `https://horizcoin-web-xyz.onrender.com`
- Railway: `https://horizcoin-web-production.up.railway.app`