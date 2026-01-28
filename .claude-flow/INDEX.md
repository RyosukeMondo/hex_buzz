# 📚 Claude-Flow Documentation Index

Complete guide to claude-flow integration for HexBuzz project.

---

## 🚀 Getting Started (Start Here!)

### 1. [SETUP_COMPLETE.md](SETUP_COMPLETE.md) (7KB)
**Setup confirmation and success checklist**
- ✅ What was configured
- 🎯 Next steps
- 💡 Example use cases
- 🔧 Useful commands

**Read this first!** It confirms everything is ready and shows you what to do next.

---

### 2. [DAEMON_QUICKSTART.md](DAEMON_QUICKSTART.md) (6KB) ⭐
**ANSWER TO YOUR QUESTION: "How to run daemon?"**
- **TL;DR**: Use MCP Server (project-specific, auto-managed)
- Quick comparison of all daemon modes
- **Which mode to use for your situation**
- 5-second setup instructions

**Read this second!** Answers your daemon question directly.

---

## 📖 Comprehensive Guides

### 3. [README.md](README.md) (12KB)
**Complete reference documentation**
- Overview and benefits
- All 5 agents explained
- All 3 workflows explained
- Swarm configurations
- Setup and usage instructions
- Monitoring and troubleshooting

**Your go-to reference** for everything claude-flow.

---

### 4. [QUICK_START.md](QUICK_START.md) (5KB)
**5-minute getting started guide**
- Fast setup (4 commands)
- 3 quick examples
- Common commands
- Understanding output
- Pro tips

**Perfect for** learning by doing.

---

### 5. [DAEMON_SETUP.md](DAEMON_SETUP.md) (12KB)
**Comprehensive daemon setup guide**
- Understanding 3 daemon modes
- Detailed comparison matrix
- Step-by-step setup for each mode
  - MCP Server (project-specific)
  - PM2 Service (system-wide)
  - systemd Service (Linux native)
  - On-Demand CLI (no daemon)
- Project-specific vs system-wide
- Advanced multi-project setup
- Monitoring and troubleshooting

**Deep dive** into all daemon options.

---

### 6. [INTEGRATION.md](INTEGRATION.md) (11KB)
**Architecture integration details**
- How claude-flow integrates with HexBuzz
- Agent-domain mapping
- Workflow integration explained
- Swarm coordination details
- Intelligence & learning systems
- Quality enforcement
- Best practices

**Understand** how everything fits together.

---

### 7. [ARCHITECTURE.md](ARCHITECTURE.md) (28KB)
**System architecture and deployment modes**
- Visual system architecture
- All deployment modes with diagrams
- Data flow diagrams
- Consensus algorithm flows
- State & storage structure
- Security architecture
- Performance characteristics
- Decision tree for choosing mode

**For architects** and those who want deep understanding.

---

## 🎯 Quick Navigation by Goal

### "I just want to get started"
1. [SETUP_COMPLETE.md](SETUP_COMPLETE.md) - Confirm setup
2. [DAEMON_QUICKSTART.md](DAEMON_QUICKSTART.md) - Choose daemon mode
3. Run: `npm run mcp:install`
4. Try it in Claude Code!

---

### "How do I run the daemon?" ← YOUR QUESTION
👉 **[DAEMON_QUICKSTART.md](DAEMON_QUICKSTART.md)** ← READ THIS!

**Short answer**:
```bash
# For you (solo dev + Claude Code):
npm run mcp:install

# That's it! Auto-managed, project-specific, zero maintenance.
```

**Is it project-specific or system-wide?**
- **MCP Server** (recommended): Project-specific
- **PM2/systemd** (optional): System-wide

See [DAEMON_QUICKSTART.md](DAEMON_QUICKSTART.md) for full comparison.

---

### "I want to learn by examples"
1. [QUICK_START.md](QUICK_START.md) - 3 hands-on examples
2. Try them in Claude Code or CLI

---

### "I need complete reference"
1. [README.md](README.md) - Full documentation
2. Bookmark for reference

---

### "I want to understand the architecture"
1. [INTEGRATION.md](INTEGRATION.md) - How it integrates
2. [ARCHITECTURE.md](ARCHITECTURE.md) - Deep dive

---

### "I work on multiple projects"
1. [DAEMON_SETUP.md](DAEMON_SETUP.md) - System-wide setup
2. Choose PM2 or systemd mode
3. Run: `npm run daemon` (select option 2 or 3)

---

### "I need this for CI/CD"
1. [DAEMON_SETUP.md](DAEMON_SETUP.md) - On-demand CLI section
2. Use CLI mode (no daemon needed)

---

## 📊 Documentation Size Overview

```
SETUP_COMPLETE.md     █████░░  7KB   - Setup confirmation
DAEMON_QUICKSTART.md  ████░░░  6KB   - Daemon guide ⭐
README.md            ████████ 12KB   - Complete reference
QUICK_START.md       ███░░░░░  5KB   - Getting started
DAEMON_SETUP.md      ████████ 12KB   - Daemon deep dive
INTEGRATION.md       ███████░ 11KB   - Architecture integration
ARCHITECTURE.md      ████████ 28KB   - System architecture
                     ==================
                     TOTAL: ~81KB
```

---

## 🔧 Quick Commands Reference

### Setup & Installation
```bash
npm run setup           # Verify setup
npm run daemon          # Interactive daemon manager
npm run mcp:install     # Install MCP server (recommended)
npm run daemon:status   # Check daemon status
```

### Agent & Workflow Management
```bash
npm run agent:list      # List available agents
npm run workflow:list   # List workflows
npm run swarm:status    # Check swarm health
```

### Monitoring & Maintenance
```bash
npm run health          # Health check
npm run metrics         # Performance metrics
npm run vector:rebuild  # Rebuild knowledge store
```

### MCP Server
```bash
npm run mcp:install     # Install
npm run mcp:remove      # Remove
claude mcp list         # List MCP servers
```

---

## 🎓 Learning Path

### Beginner (15 minutes)
1. ✅ [SETUP_COMPLETE.md](SETUP_COMPLETE.md) (2 min read)
2. ✅ [DAEMON_QUICKSTART.md](DAEMON_QUICKSTART.md) (3 min read)
3. ✅ `npm run mcp:install` (5 seconds)
4. ✅ Try example in Claude Code (10 min)

**Result**: You can use claude-flow!

---

### Intermediate (45 minutes)
1. ✅ [QUICK_START.md](QUICK_START.md) (5 min)
2. ✅ [README.md](README.md) (20 min)
3. ✅ Try all 3 workflows (20 min)

**Result**: You understand all features!

---

### Advanced (2 hours)
1. ✅ [INTEGRATION.md](INTEGRATION.md) (30 min)
2. ✅ [ARCHITECTURE.md](ARCHITECTURE.md) (60 min)
3. ✅ [DAEMON_SETUP.md](DAEMON_SETUP.md) (30 min)

**Result**: You can customize and extend!

---

## 🆘 Troubleshooting Guide

### Problem: "How do I run the daemon?"
**Solution**: [DAEMON_QUICKSTART.md](DAEMON_QUICKSTART.md)

### Problem: "MCP server not found"
**Solution**: [README.md](README.md) - Troubleshooting section

### Problem: "Agent not responding"
**Solution**: [SETUP_COMPLETE.md](SETUP_COMPLETE.md) - Troubleshooting

### Problem: "Which mode should I use?"
**Solution**: [DAEMON_QUICKSTART.md](DAEMON_QUICKSTART.md) - Comparison

### Problem: "How does consensus work?"
**Solution**: [ARCHITECTURE.md](ARCHITECTURE.md) - Consensus flows

### Problem: "Project-specific or system-wide?"
**Solution**: [DAEMON_SETUP.md](DAEMON_SETUP.md) - Comparison

---

## 📞 Where to Get Help

1. **Check logs**:
   ```bash
   # MCP server logs
   cat ~/.config/claude/logs/mcp.log

   # Claude-flow logs
   tail -f logs/claude-flow.log
   ```

2. **Health check**:
   ```bash
   npm run health
   npm run daemon:status
   ```

3. **Rebuild knowledge**:
   ```bash
   npm run vector:rebuild
   ```

4. **Review metrics**:
   ```bash
   npm run metrics
   ```

---

## 🎯 Recommended Reading Order

### For Your Question (Daemon Setup):
```
1. DAEMON_QUICKSTART.md  ← Start here! ⭐
2. DAEMON_SETUP.md       ← If you need more details
3. ARCHITECTURE.md       ← If you want deep dive
```

### For General Usage:
```
1. SETUP_COMPLETE.md     ← Confirm setup
2. QUICK_START.md        ← Learn basics
3. README.md             ← Full reference
4. INTEGRATION.md        ← Understand integration
```

---

## ✨ Summary

You have **7 comprehensive documents** totaling **~81KB** of documentation covering:

- ✅ Setup confirmation
- ✅ Daemon setup (all modes)
- ✅ Quick start guide
- ✅ Complete reference
- ✅ Architecture details
- ✅ Integration guide
- ✅ System architecture

**Your next step**:
```bash
cd .claude-flow
npm run mcp:install
```

Then in Claude Code:
```
Use the architect agent to review our project structure
```

**That's it!** 🎉

---

**Bookmark this INDEX.md** for easy navigation!
