# 🚀 Claude-Flow Daemon Quick Start

## TL;DR - Which One Should I Use?

### For You (Solo Dev + Claude Code): MCP Server ⭐
```bash
npm run mcp:install
```
Done! No daemon to manage. Auto-starts with Claude Code.

---

## 📊 Quick Comparison

| Aspect | MCP Server | PM2 Service | systemd Service |
|--------|-----------|-------------|-----------------|
| **Setup Time** | 5 seconds | 30 seconds | 1 minute |
| **Management** | Automatic | PM2 CLI | systemctl |
| **Scope** | This project | All projects | All projects |
| **When Runs** | With Claude Code | Always | Always |
| **Memory** | ~100MB on-demand | ~150MB always | ~150MB always |
| **Best For** | Single project dev | Multi-project dev | Production servers |

---

## 🎯 Recommended Approach

### 1️⃣ MCP Server (Start Here)

**Setup**:
```bash
cd .claude-flow
npm run mcp:install
```

**Verify**:
```bash
claude mcp list  # Should show claude-flow
```

**Usage** (in Claude Code):
```
Use the architect agent to review my code
```

**When to use**:
- ✅ You work on HexBuzz primarily
- ✅ You use Claude Code for development
- ✅ You want zero maintenance
- ✅ You want project-specific configuration

**When NOT to use**:
- ❌ You work on many different projects
- ❌ You need daemon running 24/7
- ❌ You want to use CLI from any directory

---

### 2️⃣ PM2 Service (If Multi-Project)

**Setup**:
```bash
npm run daemon
# Select option 2
```

**Verify**:
```bash
pm2 status claude-flow
curl http://localhost:3000/health
```

**Usage** (CLI from anywhere):
```bash
npx claude-flow@v3alpha --agent architect --task "Review code"
```

**When to use**:
- ✅ You work on multiple projects
- ✅ You want daemon always ready
- ✅ You prefer PM2 monitoring
- ✅ You use CLI frequently

**Management**:
```bash
pm2 status claude-flow    # Check status
pm2 logs claude-flow      # View logs
pm2 restart claude-flow   # Restart
pm2 stop claude-flow      # Stop
```

---

### 3️⃣ systemd Service (For Servers)

**Setup**:
```bash
npm run daemon
# Select option 3
```

**Verify**:
```bash
sudo systemctl status claude-flow
curl http://localhost:3000/health
```

**When to use**:
- ✅ You're on Linux
- ✅ You want native system integration
- ✅ You want service on boot
- ✅ You prefer systemctl

**Management**:
```bash
sudo systemctl status claude-flow     # Status
sudo systemctl restart claude-flow    # Restart
sudo systemctl stop claude-flow       # Stop
sudo journalctl -u claude-flow -f     # Logs
```

---

## 🤔 Detailed Scenarios

### Scenario 1: Solo Developer on HexBuzz
**Use**: MCP Server

**Why**:
- Configuration is project-specific and in git
- Automatic lifecycle (no daemon management)
- Works perfectly with Claude Code
- Zero maintenance

**Setup**:
```bash
npm run mcp:install
```

---

### Scenario 2: Working on 5+ Projects
**Use**: PM2 Service

**Why**:
- One daemon serves all projects
- Always warm (faster response)
- Can share learning across projects
- Easy to monitor with PM2

**Setup**:
```bash
npm run daemon  # Select option 2
```

**Per-Project Config**:
```bash
# Each project can have .claude-flow/ directory
# Daemon loads config based on working directory
```

---

### Scenario 3: Team Development
**Use**: MCP Server (each dev)

**Why**:
- Configuration in git (consistent across team)
- Each developer installs MCP server
- Project-specific agents and workflows
- No server infrastructure needed

**Team Setup**:
```bash
# Each team member runs:
cd /path/to/hex_buzz/.claude-flow
npm run mcp:install
```

---

### Scenario 4: CI/CD Pipeline
**Use**: On-Demand CLI (no daemon)

**Why**:
- No daemon overhead in CI
- Spawns fresh for each run
- Stateless and reproducible

**CI Config**:
```yaml
# .github/workflows/code-review.yml
- name: Code Review
  run: |
    cd .claude-flow
    npx claude-flow@v3alpha --workflow code_review --path "lib/"
```

---

## 🔧 Daemon Manager Tool

Interactive menu for setup:
```bash
npm run daemon
```

Options:
1. **Install MCP Server** - Project-specific, auto-managed
2. **Install PM2 Service** - System-wide, always running
3. **Install systemd Service** - Native Linux service
4. **Check Status** - See what's running
5. **Uninstall All** - Clean removal

**CLI Usage**:
```bash
npm run daemon -- mcp       # Install MCP server
npm run daemon -- pm2       # Install PM2 service
npm run daemon -- systemd   # Install systemd service
npm run daemon -- status    # Check status
npm run daemon -- uninstall # Remove all
```

---

## 📊 Check What's Running

```bash
npm run daemon:status
```

Shows:
- MCP Server status
- PM2 Service status
- systemd Service status
- Health check on port 3000

---

## 💡 Pro Tips

### Tip 1: Start with MCP Server
It's the easiest and most integrated with Claude Code:
```bash
npm run mcp:install
```

### Tip 2: Upgrade to PM2 Later
If you need multi-project support:
```bash
npm run daemon  # Select PM2
```
Both can coexist!

### Tip 3: Check Status Anytime
```bash
npm run daemon:status
```

### Tip 4: Use CLI for Scripts
Even with MCP server, you can use CLI:
```bash
npx claude-flow@v3alpha --agent architect --task "Task description"
```

### Tip 5: Project-Specific Config Wins
When multiple modes installed, project config takes priority.

---

## 🚨 Troubleshooting

### "MCP server not found"
```bash
# Check installation
claude mcp list

# Reinstall
npm run mcp:install
```

### "PM2 service not starting"
```bash
# Check logs
pm2 logs claude-flow

# Restart
pm2 restart claude-flow

# Check config
pm2 describe claude-flow
```

### "Port 3000 already in use"
```bash
# Find what's using it
lsof -i :3000

# Or change port in config
# Edit config/claude-flow.yaml - add:
# server:
#   port: 3001
```

### "Can't connect to daemon"
```bash
# Check if anything is running
npm run daemon:status

# Check health
curl http://localhost:3000/health
```

---

## 📚 Related Documentation

- [DAEMON_SETUP.md](DAEMON_SETUP.md) - Comprehensive daemon guide
- [README.md](README.md) - Full claude-flow documentation
- [INTEGRATION.md](INTEGRATION.md) - Architecture integration details

---

## 🎬 Get Started Now

**Recommended first step**:
```bash
npm run mcp:install
```

Then in Claude Code:
```
Use the architect agent to review the project structure
```

That's it! 🎉
