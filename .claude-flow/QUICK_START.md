# Claude-Flow Quick Start Guide

Get up and running with Claude-Flow in 5 minutes.

## ⚡ Fast Setup

```bash
# 1. Navigate to claude-flow directory
cd .claude-flow

# 2. Run setup script
node scripts/setup.js

# 3. Install MCP server in Claude Code
npm run mcp:install

# 4. Verify installation
npm run health
```

Done! Claude Code now has multi-agent capabilities.

## 🎯 Quick Examples

### Example 1: Feature Development with Swarm

**In Claude Code, say:**
```
Use the feature team swarm to add a dark mode toggle to the settings screen.
```

**Or via CLI:**
```bash
npx claude-flow@v3alpha --swarm feature_team \
  --task "Add dark mode toggle to settings screen"
```

**What happens:**
1. Architect plans the implementation
2. Flutter Specialist implements UI changes
3. Test Specialist writes tests
4. All agents reach consensus via Raft algorithm

---

### Example 2: Bug Fix (No Band-Aids!)

**In Claude Code, say:**
```
Use the bug fix workflow to solve the Firebase timeout issue.
```

**Or via CLI:**
```bash
npx claude-flow@v3alpha --workflow bug_fix \
  --task "Fix Firebase authentication timeout"
```

**What happens:**
1. Swarm reproduces and identifies root cause
2. Architect designs proper architectural fix
3. Firebase Specialist implements
4. Test Specialist adds regression tests
5. Architect verifies no band-aids were applied

---

### Example 3: Code Review with Consensus

**In Claude Code, say:**
```
Have the review committee evaluate my changes to lib/services/game/
```

**Or via CLI:**
```bash
npx claude-flow@v3alpha --workflow code_review \
  --path "lib/services/game"
```

**What happens:**
1. All 5 agents review in parallel
2. Byzantine consensus ensures quality
3. Weighted voting (Architect: 2x, Security: 1.5x)
4. Approval requires 70% weighted agreement

---

## 🔧 Common Commands

```bash
# List available agents
npm run agent:list

# List workflows
npm run workflow:list

# Check swarm status
npm run swarm:status

# View performance metrics
npm run metrics

# Health check
npm run health

# Rebuild vector knowledge store
npm run vector:rebuild
```

---

## 🎓 Usage Patterns

### Pattern 1: Single Agent Task

**When to use**: Simple, focused tasks within one domain

```bash
npx claude-flow@v3alpha \
  --agent flutter_specialist \
  --task "Optimize GameBoard widget rebuilds"
```

### Pattern 2: Workflow Task

**When to use**: Multi-phase tasks requiring coordination

```bash
npx claude-flow@v3alpha \
  --workflow feature_development \
  --task "Add social sharing feature"
```

### Pattern 3: Swarm Task

**When to use**: Complex tasks requiring real-time collaboration

```bash
npx claude-flow@v3alpha \
  --swarm feature_team \
  --task "Refactor authentication system"
```

---

## 📊 Understanding Output

### Agent Consensus Messages

```
[CONSENSUS] Raft quorum reached (3/3 agents agree)
  ✓ flutter_specialist: approved (high confidence)
  ✓ firebase_specialist: approved (medium confidence)
  ✓ architect: approved (high confidence)

Decision: APPROVED
Implementation plan committed to memory.
```

### Quality Gate Failures

```
[QUALITY_GATE] Review failed - code standards violation
  ✗ File size: 612 lines (max: 500)
  ✗ Function size: 78 lines (max: 50)
  ✗ Test coverage: 72% (min: 80%)

Action: REJECTED
Fix required before approval.
```

### Cost Tracking

```
[METRICS] Task completed
  Duration: 2m 34s
  API Calls: 18
  Tokens Used: 12,450
  Cost: $0.08
  Cost Reduction: 42% vs single-agent
```

---

## 🚨 Troubleshooting

### Issue: MCP Server Not Found

```bash
# Re-install MCP server
npm run mcp:install

# Verify in Claude Code
claude mcp list
```

### Issue: Agent Not Responding

```bash
# Check health
npm run health

# View logs
tail -f ../logs/claude-flow.log

# Rebuild vector store
npm run vector:rebuild
```

### Issue: Consensus Timeout

**Cause**: Agents can't reach agreement within timeout

**Solution**:
1. Check logs for agent disagreements
2. Adjust timeout in swarm config
3. Consider different consensus algorithm

---

## 💡 Pro Tips

1. **Let Swarms Collaborate**: Don't manually coordinate agents. Use workflows and swarms.

2. **Trust Quality Gates**: Agents enforce strict standards. If rejected, there's a good reason.

3. **Review Metrics**: Check `npm run metrics` to see cost savings and performance.

4. **Use Appropriate Workflow**:
   - New feature → `feature_development`
   - Bug → `bug_fix` (no band-aids!)
   - Review → `code_review`

5. **Learn from Patterns**: RuVector learns successful patterns. Review with:
   ```bash
   npx claude-flow@v3alpha patterns show
   ```

---

## 📖 Next Steps

- Read full documentation: [README.md](README.md)
- Explore agent configs: [agents/](agents/)
- Review workflows: [workflows/](workflows/)
- Check domain structure: [domains/](domains/)
- Understand swarms: [swarms/](swarms/)

---

**Ready to go!** Try your first command:

```bash
npx claude-flow@v3alpha --agent architect --task "Review project structure"
```

Or in Claude Code:
```
Use the architect agent to review our project structure and suggest improvements.
```
