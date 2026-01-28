# Claude-Flow Daemon Setup Guide

## 🤔 Understanding Claude-Flow Architecture

Claude-flow can run in three modes:

### 1. **MCP Server Mode** (Recommended for Claude Code)
- **Daemon**: Managed by Claude Code automatically
- **Scope**: Can be project-specific OR global
- **Lifecycle**: Starts when Claude Code starts, stops when it exits
- **Best for**: Interactive development with Claude Code

### 2. **Local Service Mode** (Standalone Daemon)
- **Daemon**: Background service you manage
- **Scope**: One per dev PC (system-wide)
- **Lifecycle**: Runs continuously, independent of Claude Code
- **Best for**: Multiple projects, CLI usage, team coordination

### 3. **On-Demand CLI Mode** (No Daemon)
- **Daemon**: None - spawns agents per command
- **Scope**: Per invocation
- **Lifecycle**: Starts and stops with each command
- **Best for**: One-off tasks, CI/CD pipelines

---

## 📊 Comparison Matrix

| Feature | MCP Server | Local Service | On-Demand CLI |
|---------|-----------|---------------|---------------|
| **Startup** | Auto by Claude Code | Manual/systemd | Per command |
| **Performance** | Fast (warm) | Fastest (always warm) | Slowest (cold start) |
| **Resource Usage** | Low (on-demand) | Higher (always running) | Lowest (temporary) |
| **Project Context** | Project-specific | Shared across projects | Per invocation |
| **Vector Store** | Project-specific | Can be shared | Ephemeral |
| **Multi-Project** | Need multiple configs | Single daemon serves all | N/A |
| **Team Sharing** | No | Yes (if networked) | No |
| **Best Use** | Solo dev + Claude Code | Multi-project dev | CI/CD, scripts |

---

## 🎯 Recommended Setup: Hybrid Approach

For your HexBuzz project, I recommend:

### Primary: MCP Server (Project-Specific)
Use for interactive Claude Code development:
```bash
cd /home/rmondo/repos/hex_buzz/.claude-flow
npm run mcp:install
```

**Benefits**:
- ✅ Automatic startup/shutdown
- ✅ Project-specific configuration
- ✅ Zero maintenance
- ✅ Vector store learns from YOUR project

### Secondary: Local Service (Optional)
If you work on multiple projects:
```bash
# Install claude-flow globally
npm install -g claude-flow@v3alpha

# Run as system service
claude-flow daemon start --port 3000
```

**Benefits**:
- ✅ Serves multiple projects
- ✅ Always warm (faster)
- ✅ Shared learning across projects
- ✅ Can be used by CLI from any directory

---

## 📝 Setup Instructions

### Option 1: MCP Server (Project-Specific) ⭐ RECOMMENDED

#### Manual Installation
```bash
# From project root
claude mcp add claude-flow -- npx -y claude-flow@v3alpha mcp start
```

#### Or using npm script
```bash
cd .claude-flow
npm run mcp:install
```

#### Verify
```bash
# List MCP servers
claude mcp list

# Should show:
# claude-flow - Claude-Flow multi-agent orchestration
```

#### Configuration Location
```
~/.config/claude/mcp.json
```

The MCP server will:
- Start automatically when Claude Code launches
- Load project-specific config from `.claude-flow/config/claude-flow.yaml`
- Use project-specific vector store in `.claude-flow/vector_store/`
- Stop when Claude Code exits

---

### Option 2: Local Service (System-Wide)

#### A. Using systemd (Linux)

**1. Install globally**
```bash
npm install -g claude-flow@v3alpha
```

**2. Create systemd service**
```bash
sudo nano /etc/systemd/system/claude-flow.service
```

**3. Service configuration**
```ini
[Unit]
Description=Claude-Flow Multi-Agent Orchestration Platform
After=network.target

[Service]
Type=simple
User=rmondo
WorkingDirectory=/home/rmondo/.claude-flow
ExecStart=/usr/bin/node /usr/local/bin/claude-flow daemon start --port 3000 --config /home/rmondo/.claude-flow/config.yaml
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="NODE_ENV=production"

[Install]
WantedBy=multi-user.target
```

**4. Enable and start**
```bash
sudo systemctl daemon-reload
sudo systemctl enable claude-flow
sudo systemctl start claude-flow
sudo systemctl status claude-flow
```

**5. Check logs**
```bash
sudo journalctl -u claude-flow -f
```

#### B. Using PM2 (Cross-Platform)

**1. Install PM2**
```bash
npm install -g pm2 claude-flow@v3alpha
```

**2. Create ecosystem config**
```bash
nano ~/claude-flow-ecosystem.config.js
```

```javascript
module.exports = {
  apps: [{
    name: 'claude-flow',
    script: 'claude-flow',
    args: 'daemon start --port 3000',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '2G',
    env: {
      NODE_ENV: 'production',
      CLAUDE_FLOW_CONFIG: '/home/rmondo/.claude-flow/config.yaml'
    }
  }]
};
```

**3. Start with PM2**
```bash
pm2 start ~/claude-flow-ecosystem.config.js
pm2 save
pm2 startup  # Enable on boot
```

**4. Monitor**
```bash
pm2 status
pm2 logs claude-flow
pm2 monit
```

#### C. Using Docker

**1. Create Dockerfile**
```bash
nano ~/.claude-flow/Dockerfile
```

```dockerfile
FROM node:20-alpine

WORKDIR /app

# Install claude-flow
RUN npm install -g claude-flow@v3alpha

# Copy configuration
COPY config.yaml /app/config.yaml

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health')"

# Run daemon
CMD ["claude-flow", "daemon", "start", "--port", "3000", "--config", "/app/config.yaml"]
```

**2. Build and run**
```bash
cd ~/.claude-flow
docker build -t claude-flow .
docker run -d --name claude-flow -p 3000:3000 -v $(pwd)/vector_store:/app/vector_store claude-flow
```

**3. Auto-start on boot**
```bash
docker update --restart unless-stopped claude-flow
```

---

### Option 3: On-Demand CLI (No Daemon)

Simply invoke directly:
```bash
# No setup needed
npx claude-flow@v3alpha --agent architect --task "Review code"
```

Each invocation:
- Spawns fresh agents
- Loads configuration
- Executes task
- Exits

**Use in CI/CD**:
```yaml
# .github/workflows/code-review.yml
- name: Run Claude-Flow Review
  run: |
    npx claude-flow@v3alpha \
      --workflow code_review \
      --path "lib/services"
```

---

## 🏗️ Project-Specific vs System-Wide

### Project-Specific (Current Setup)

**Configuration**: `/home/rmondo/repos/hex_buzz/.claude-flow/`

**Pros**:
- ✅ Configuration versioned with project
- ✅ Team members get same setup
- ✅ Project-specific agents and workflows
- ✅ Vector store learns from this project only
- ✅ Can customize per project

**Cons**:
- ❌ Each project needs own setup
- ❌ Can't share learning across projects
- ❌ Multiple MCP servers if multiple projects

**Best for**:
- Single project focus
- Team collaboration (config in git)
- Project-specific customization

### System-Wide (One Daemon)

**Configuration**: `~/.claude-flow/`

**Pros**:
- ✅ One daemon serves all projects
- ✅ Shared learning across projects
- ✅ Faster (always warm)
- ✅ Less resource usage overall
- ✅ Centralized monitoring

**Cons**:
- ❌ Configuration not in project repo
- ❌ Can't have project-specific agents
- ❌ Team members need manual setup
- ❌ Potential conflicts between projects

**Best for**:
- Multi-project developers
- Solo developers with many projects
- Consistent workflow across projects

---

## 🎯 Recommended for Your Situation

Based on your HexBuzz project:

### Use MCP Server (Project-Specific)

**Why?**
1. Configuration is in `.claude-flow/` (can be committed to git)
2. Team members can use same setup
3. Automatic lifecycle management
4. Zero maintenance
5. Perfect for Flutter + Firebase dual-stack

**Setup** (if not done already):
```bash
cd /home/rmondo/repos/hex_buzz/.claude-flow
npm run mcp:install
```

**Verify**:
```bash
# Check MCP servers
claude mcp list

# Should show claude-flow
```

**Usage**:
Just talk to Claude Code naturally:
```
Use the feature team swarm to add dark mode
```

### Optional: Add CLI for Scripts

For CI/CD and scripts, use on-demand:
```bash
# In your CI/CD pipeline
npx claude-flow@v3alpha --workflow code_review --path "lib/"
```

---

## 🔧 Advanced: Multi-Project Setup

If you work on multiple projects and want shared learning:

### 1. Global Config
```bash
mkdir -p ~/.claude-flow
cp /home/rmondo/repos/hex_buzz/.claude-flow/config/claude-flow.yaml ~/.claude-flow/
```

### 2. Project Overrides
```bash
# In each project's .claude-flow/config/claude-flow.yaml
extends: "~/.claude-flow/claude-flow.yaml"

# Project-specific overrides
project:
  name: "hex_buzz"

agents:
  - load: "~/.claude-flow/agents/*.yaml"  # Global agents
  - load: ".claude-flow/agents/*.yaml"     # Project-specific agents
```

### 3. Shared Vector Store
```yaml
# ~/.claude-flow/claude-flow.yaml
intelligence:
  vector_store:
    type: "ruvector"
    persistence_path: "~/.claude-flow/vector_store"  # Shared across projects
```

---

## 📊 Monitoring & Management

### MCP Server

**Check status**:
```bash
claude mcp list
```

**View logs**:
```bash
# Check Claude Code logs
~/.config/claude/logs/
```

**Restart**:
```bash
# Restart Claude Code or:
claude mcp remove claude-flow
claude mcp add claude-flow -- npx -y claude-flow@v3alpha mcp start
```

### Local Service (systemd)

```bash
sudo systemctl status claude-flow
sudo systemctl restart claude-flow
sudo journalctl -u claude-flow -f
```

### Local Service (PM2)

```bash
pm2 status claude-flow
pm2 restart claude-flow
pm2 logs claude-flow
pm2 monit
```

### Health Check

```bash
# If running as service
curl http://localhost:3000/health

# Response:
# {
#   "status": "healthy",
#   "agents": 5,
#   "workflows": 3,
#   "vector_store": "ready"
# }
```

---

## 🚨 Troubleshooting

### MCP Server Not Starting

```bash
# Check Node version
node --version  # Need >= 18

# Check MCP config
cat ~/.config/claude/mcp.json

# Remove and re-add
claude mcp remove claude-flow
cd /home/rmondo/repos/hex_buzz/.claude-flow
npm run mcp:install
```

### Service Won't Start (systemd)

```bash
# Check service status
sudo systemctl status claude-flow

# View detailed logs
sudo journalctl -u claude-flow -n 50

# Check permissions
sudo systemctl cat claude-flow
```

### PM2 Issues

```bash
# View logs
pm2 logs claude-flow --lines 100

# Check process
pm2 describe claude-flow

# Restart
pm2 restart claude-flow
```

---

## 💡 Best Practices

### 1. Start Simple
- Use MCP Server for primary development
- Add services only if needed

### 2. Project-Specific Config
- Keep `.claude-flow/` in git
- Team gets consistent setup
- CI/CD can use same config

### 3. Monitor Resources
```bash
# Check memory usage
ps aux | grep claude-flow

# With PM2
pm2 monit
```

### 4. Regular Maintenance
```bash
# Rebuild vector store periodically
npm run vector:rebuild

# Check metrics
npm run metrics
```

### 5. Security
- Don't expose daemon to network (use localhost only)
- Keep vector store in `.gitignore`
- Restrict file access permissions

---

## 📚 Summary

**Your Best Setup**:

1. **MCP Server** (primary) - Already configured! ✅
   - Auto-managed by Claude Code
   - Project-specific
   - Zero maintenance

2. **Optional Local Service** (if multi-project):
   - PM2 approach (easiest)
   - System-wide daemon
   - Shared learning

3. **CLI for CI/CD**:
   - On-demand execution
   - No daemon needed

**Next Step**:
```bash
cd /home/rmondo/repos/hex_buzz/.claude-flow
npm run mcp:install
```

Done! 🎉
