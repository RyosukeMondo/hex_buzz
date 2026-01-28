# Claude-Flow Integration for HexBuzz

Enterprise AI Agent Orchestration platform integrated with HexBuzz development workflow.

## 📋 Overview

Claude-Flow transforms your development process by enabling multiple specialized AI agents to collaborate on complex software engineering tasks. This setup is tailored for HexBuzz's Flutter + Firebase architecture.

### Key Benefits

- **30-50% Cost Reduction**: Intelligent routing and task decomposition
- **Multi-Agent Collaboration**: 5 specialized agents working in swarms
- **Quality Enforcement**: Automated code standards and architecture review
- **Goal Retention**: Prevents agent drift through hierarchical coordination
- **Learning System**: Agents learn from successful patterns (RuVector)

## 🎯 Available Agents

### 1. Flutter Specialist (`flutter_specialist`)
**Expertise**: Flutter UI, Dart, Riverpod state management, widget composition

**Capabilities**:
- Analyze and implement Flutter code
- Optimize widget rebuilds
- Debug state management issues
- Write widget and unit tests
- Enforce Flutter best practices

**Standards**:
- Max 500 lines/file, 50 lines/function
- 80% test coverage minimum
- SOLID principles with dependency injection

### 2. Firebase Specialist (`firebase_specialist`)
**Expertise**: Cloud Functions, Firestore, Firebase Auth, TypeScript

**Capabilities**:
- Implement Cloud Functions
- Optimize Firestore queries
- Design security rules
- Handle authentication flows
- Monitor performance

**Standards**:
- Structured JSON logging
- Fail-fast validation
- Custom exception hierarchy
- No secrets in code

### 3. Test Specialist (`test_specialist`)
**Expertise**: Unit, widget, integration testing, TDD, code coverage

**Capabilities**:
- Write comprehensive tests (AAA pattern)
- Achieve 80% overall, 90% critical path coverage
- Mock external dependencies (Mocktail)
- Identify test gaps
- Refactor tests for maintainability

**Standards**:
- Descriptive test names
- Isolated, independent tests
- One assertion per test (generally)

### 4. Security Specialist (`security_specialist`)
**Expertise**: OWASP Top 10, Firebase security, input validation, auth patterns

**Capabilities**:
- Scan for vulnerabilities
- Review Firestore security rules
- Validate authentication flows
- Check input sanitization
- Audit dependencies

**Standards**:
- No hardcoded secrets
- Prevent injection attacks
- No PII in logs
- Principle of least privilege

### 5. Architect (`architect`)
**Expertise**: SOLID principles, clean architecture, design patterns, code review

**Capabilities**:
- Design system architecture
- Review code structure
- Identify code smells
- Enforce quality standards
- Plan implementations

**Standards**:
- SOLID, DI, SSOT, KISS, SLAP
- No band-aid fixes (address root causes)
- Self-sufficient components
- Proper abstractions

## 🔄 Workflows

### Feature Development Workflow
**Use case**: Implement new features from planning to review

**Phases**:
1. **Planning** (Architect) - Design architecture and plan implementation
2. **Implementation** (Swarm: Flutter + Firebase specialists) - Parallel development with consensus
3. **Testing** (Test Specialist) - Comprehensive test coverage
4. **Security Review** (Security Specialist) - Vulnerability scanning
5. **Code Review** (Architect) - Final quality gates

**Invoke**:
```bash
npx claude-flow@v3alpha --workflow feature_development --task "Add leaderboard feature"
```

### Bug Fix Workflow
**Use case**: Root cause analysis and proper fixes (no band-aids!)

**Phases**:
1. **Investigation** (Swarm) - Reproduce and identify root cause
2. **Fix Planning** (Architect) - Design proper architectural fix
3. **Implementation** (Domain specialist) - Implement root cause fix
4. **Testing** (Test Specialist) - Regression tests + existing tests
5. **Review** (Architect) - Verify no band-aids

**Invoke**:
```bash
npx claude-flow@v3alpha --workflow bug_fix --task "Fix authentication timeout issue"
```

### Code Review Workflow
**Use case**: Multi-agent consensus-based code review

**Phases**:
1. **Automated Analysis** (Architect) - Metrics and coverage checks
2. **Domain Reviews** (All specialists in parallel) - Byzantine consensus
3. **Architectural Review** (Architect) - SOLID compliance verification
4. **Consensus Decision** (Swarm) - Raft consensus for approval

**Invoke**:
```bash
npx claude-flow@v3alpha --workflow code_review --path "lib/services/game"
```

## 🐝 Swarms

### Feature Team Swarm
**Topology**: Queen-Worker (Hierarchical)
- **Queen**: Architect (coordinates, resolves conflicts)
- **Workers**: Flutter Specialist, Firebase Specialist, Test Specialist
- **Consensus**: Raft algorithm (leader-based)

### Review Committee Swarm
**Topology**: Peer-to-Peer (Consensus)
- **Participants**: All 5 agents
- **Consensus**: Byzantine fault tolerance
- **Voting**: Weighted (Architect: 2x, Security: 1.5x)

## 🏗️ Domain Structure

### Flutter App Domain (`lib/`)
```
lib/
├── ui/          # Screens, widgets, themes
├── models/      # Data models (no dependencies)
├── providers/   # Riverpod state management
└── services/    # Business logic, Firebase integration
```

**Agent**: Flutter Specialist → Architect (review)

### Firebase Backend Domain (`functions/`)
```
functions/src/
├── endpoints/     # HTTP/callable functions
├── services/      # Business logic
├── repositories/  # Data access layer
├── models/        # Type definitions
└── triggers/      # Firestore triggers
```

**Agent**: Firebase Specialist → Security Specialist → Architect

### Testing Domain (`test/`, `integration_test/`)
- **Unit tests**: 80% coverage
- **Widget tests**: 80% coverage
- **Integration tests**: 70% coverage
- **Critical paths**: 90% coverage

**Agent**: Test Specialist

## 🚀 Setup & Installation

### 1. Run Setup Script
```bash
cd .claude-flow
node scripts/setup.js
```

### 2. Install MCP Server
```bash
# Option A: Using npm script
npm run mcp:install

# Option B: Manual installation
claude mcp add claude-flow -- npx -y claude-flow@v3alpha mcp start
```

### 3. Verify Installation
```bash
# List available agents
npm run agent:list

# List workflows
npm run workflow:list

# Health check
npm run health
```

## 💻 Usage

### CLI Usage

**Invoke specific agent**:
```bash
npx claude-flow@v3alpha --agent flutter_specialist --task "Optimize GameScreen widget tree"
```

**Run workflow**:
```bash
npx claude-flow@v3alpha --workflow feature_development --task "Add multiplayer mode"
```

**Launch swarm**:
```bash
npx claude-flow@v3alpha --swarm feature_team --task "Refactor authentication system"
```

### Claude Code Integration (MCP)

Once MCP server is installed, Claude Code automatically has access to:
- All 5 specialized agents
- 3 coordinated workflows
- 2 swarm configurations
- Project-specific knowledge domains

**In Claude Code, you can say**:
- "Use the feature team swarm to add a social sharing feature"
- "Run the bug fix workflow for the Firebase timeout issue"
- "Have the review committee evaluate my recent changes"

### Available npm Scripts

```bash
npm run mcp:start          # Start MCP server manually
npm run agent:list         # List all configured agents
npm run workflow:list      # List all workflows
npm run swarm:status       # Check swarm health
npm run vector:rebuild     # Rebuild vector knowledge store
npm run metrics            # View performance metrics
npm run health             # Full health check
```

## ⚙️ Configuration

### Main Configuration
**File**: `config/claude-flow.yaml`

Key settings:
- **Intelligence**: RuVector with HNSW indexing (150x faster)
- **Routing**: Q-Learning with 40% cost reduction target
- **Consensus**: Raft (default), Byzantine (reviews), Gossip
- **Security**: AI Defence, injection prevention, path traversal blocking

### Agent Configuration
**Location**: `agents/*.yaml`

Each agent has:
- Expertise domains
- Capabilities
- Code standards enforcement
- Knowledge domains (which files/paths they know)
- Review checklists

### Workflow Configuration
**Location**: `workflows/*.yaml`

Each workflow defines:
- Sequential phases
- Agent/swarm assignments
- Consensus requirements
- Success criteria
- Failure handling

### Domain Configuration
**Location**: `domains/*.yaml`

Each domain defines:
- Directory structure
- Layer responsibilities
- Dependency rules
- Agent assignments
- Quality gates

## 📊 Monitoring

### Metrics Tracked
- Agent performance and coordination time
- Cost tracking and optimization
- Consensus timing and success rates
- Error rates by agent
- Test coverage trends

### Logs
- **Location**: `logs/claude-flow.log`
- **Format**: Structured JSON
- **Levels**: debug, info, warn, error

### Alerts
- Worker overloaded
- Consensus timeout
- Task failure rate high
- Critical issues detected

## 🔒 Security

### Restricted Paths
Claude-Flow blocks access to:
- `.env`, `.env.*`
- `**/*.key`, `**/*.pem`
- `**/secrets/**`
- `firebase-adminsdk-*.json`

### Allowed Operations
- read, write (code files)
- execute_tests
- deploy_functions
- git_operations

### AI Defence
- Injection prevention
- Path traversal blocking
- Strict input validation

## 🎓 Best Practices

### 1. Let Agents Collaborate
Don't manually coordinate. Use workflows and swarms:
```bash
# Bad: Manual coordination
--agent flutter_specialist ...  # then manually run firebase_specialist

# Good: Use swarm
--swarm feature_team --task "..."
```

### 2. Use Appropriate Workflow
- **New feature**: feature_development workflow
- **Bug fix**: bug_fix workflow (ensures no band-aids!)
- **Code review**: code_review workflow

### 3. Trust the Quality Gates
Agents enforce:
- Max 500 lines/file, 50 lines/function
- 80% test coverage (90% critical paths)
- SOLID principles
- No band-aid fixes
- Security best practices

### 4. Review Agent Decisions
Agents reach consensus but provide reasoning:
```bash
npm run metrics  # See decision patterns
```

### 5. Learn from Patterns
RuVector learns successful patterns. Review:
```bash
npx claude-flow@v3alpha patterns show
```

## 🐛 Troubleshooting

### MCP Server Won't Start
```bash
# Check Node version (requires >=18)
node --version

# Verify configuration
cat mcp-config.json

# Check logs
tail -f ../logs/claude-flow.log
```

### Consensus Timeout
- Reduce quorum size in swarm config
- Increase timeout values
- Check agent health: `npm run health`

### Poor Agent Performance
```bash
# Rebuild vector store
npm run vector:rebuild

# Check metrics
npm run metrics

# Review logs for errors
tail -f ../logs/claude-flow.log
```

### Agent Disagreement
- Review agent reasoning in logs
- Adjust consensus algorithm (Raft vs Byzantine)
- Modify vote weights in swarm config

## 📚 Additional Resources

- [Claude-Flow GitHub](https://github.com/ruvnet/claude-flow)
- [HexBuzz Development Guidelines](../README.md)
- [Firebase Setup](../FIREBASE_SETUP.md)
- [CI/CD Pipeline](../.github/workflows/)

## 🤝 Contributing

When modifying claude-flow configuration:

1. Test changes: `npm run health`
2. Verify agents: `npm run agent:list`
3. Check workflows: `npm run workflow:list`
4. Update this README
5. Commit with descriptive message

## 📝 License

Claude-Flow is part of the HexBuzz project. See main project LICENSE.

---

**Questions or Issues?**
- Check logs: `logs/claude-flow.log`
- Run health check: `npm run health`
- Review metrics: `npm run metrics`
