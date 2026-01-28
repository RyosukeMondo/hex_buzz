# Claude-Flow Integration Guide for HexBuzz

This document explains how Claude-Flow is integrated into the HexBuzz project.

## 🏗️ Architecture Overview

```
HexBuzz Project
│
├── Flutter App (lib/)
│   ├── UI Layer (screens, widgets)
│   ├── Models (data structures)
│   ├── Providers (Riverpod state)
│   └── Services (business logic)
│
├── Firebase Backend (functions/)
│   ├── Endpoints (HTTP/callable)
│   ├── Services (business logic)
│   ├── Repositories (data access)
│   └── Triggers (Firestore events)
│
├── Testing Infrastructure (test/, integration_test/)
│   ├── Unit Tests
│   ├── Widget Tests
│   └── Integration Tests
│
└── Claude-Flow (.claude-flow/)
    ├── Agents (5 specialists)
    ├── Workflows (3 coordinated flows)
    ├── Domains (3 knowledge domains)
    ├── Swarms (2 collaboration patterns)
    └── Configuration (vector store, routing, consensus)
```

## 🤖 Agent-Domain Mapping

### Flutter App Domain
**Primary Agent**: `flutter_specialist`
- Handles all Dart/Flutter code
- Optimizes widget trees
- Manages Riverpod state
- Enforces Flutter best practices

**Review Agent**: `architect`
- Validates SOLID principles
- Checks code metrics
- Ensures clean architecture

**Testing Agent**: `test_specialist`
- Writes widget tests
- Ensures 80%+ coverage

### Firebase Backend Domain
**Primary Agent**: `firebase_specialist`
- Implements Cloud Functions
- Designs Firestore schemas
- Optimizes queries
- Manages authentication

**Security Agent**: `security_specialist`
- Reviews security rules
- Validates auth flows
- Scans vulnerabilities

**Review Agent**: `architect`
- Validates architecture
- Checks dependency injection

### Testing Domain
**Primary Agent**: `test_specialist`
- Writes all test types
- Analyzes coverage
- Identifies gaps

**Support Agents**:
- `flutter_specialist` - Widget test assistance
- `firebase_specialist` - Function test assistance

## 🔄 Workflow Integration

### 1. Feature Development Workflow

**Trigger**: New feature request

**Flow**:
```
Planning (Architect)
    ↓
Implementation (Swarm: Flutter + Firebase)
    ↓ (parallel)
Testing (Test Specialist) + Security Review (Security Specialist)
    ↓
Code Review (Architect)
    ↓
Approval / Rejection
```

**Example**:
```bash
# User task: "Add social sharing feature"

# Phase 1: Architect plans
- Analyzes requirements
- Designs architecture (frontend + backend)
- Plans implementation steps

# Phase 2: Swarm implements (Raft consensus)
- Flutter Specialist: UI components, sharing dialog
- Firebase Specialist: Share tracking, analytics function
- Agents reach consensus on approach

# Phase 3: Parallel quality checks
- Test Specialist: Unit + widget + integration tests
- Security Specialist: Input validation, auth checks

# Phase 4: Final review
- Architect validates SOLID, metrics, coverage
- Approves or requests changes
```

### 2. Bug Fix Workflow

**Trigger**: Bug report

**Flow**:
```
Investigation (Swarm: All specialists)
    ↓
Fix Planning (Architect) - No band-aids!
    ↓
Implementation (Domain specialist)
    ↓
Testing (Test Specialist) - Regression tests
    ↓
Review (Architect) - Verify root cause fixed
```

**Example**:
```bash
# User task: "Fix authentication timeout"

# Phase 1: Root cause analysis (Gossip consensus)
- Flutter Specialist: Checks UI state management
- Firebase Specialist: Analyzes Cloud Function timeout
- Architect: Reviews architecture
- Consensus: Identified root cause in token refresh logic

# Phase 2: Architect plans proper fix
- Designs token refresh strategy
- Ensures no band-aid solutions
- Plans affected areas

# Phase 3: Firebase Specialist implements
- Fixes root cause (not symptoms)
- Maintains code standards

# Phase 4: Test Specialist adds regression tests
- Tests timeout scenario
- Verifies fix works
- Ensures coverage maintained

# Phase 5: Architect verifies
- Confirms root cause addressed
- No workarounds or band-aids
- Quality standards met
```

### 3. Code Review Workflow

**Trigger**: PR or commit review request

**Flow**:
```
Automated Analysis (Architect)
    ↓
Parallel Domain Reviews (All specialists - Byzantine consensus)
    ↓
Architectural Review (Architect)
    ↓
Consensus Decision (Committee - Raft voting)
```

**Example**:
```bash
# User task: "Review changes to lib/services/game/"

# Phase 1: Automated checks
- File sizes, function sizes
- Test coverage metrics

# Phase 2: Parallel reviews (Byzantine consensus)
- Flutter Specialist: Widget patterns, state management
- Firebase Specialist: N/A (no backend changes)
- Test Specialist: Test quality, coverage
- Security Specialist: Input validation, auth
- Agents can tolerate 1 faulty agent

# Phase 3: Architectural review
- SOLID compliance
- Dependency injection
- Abstraction quality

# Phase 4: Voting (Raft consensus)
- Weighted votes (Architect: 2x, Security: 1.5x)
- Requires 70% agreement
- Generates action items if rejected
```

## 🐝 Swarm Coordination

### Feature Team Swarm (Hierarchical)

**Structure**:
```
        [Architect Queen]
              |
    +---------+---------+
    |         |         |
[Flutter]  [Firebase]  [Test]
 Worker     Worker     Worker
```

**Coordination**:
- **Raft consensus** (leader-based)
- Architect makes final decisions
- Workers can request help
- Automatic task distribution

**Use cases**:
- Feature development
- Major refactoring
- System design changes

### Review Committee Swarm (Peer-to-Peer)

**Structure**:
```
[Architect] ←→ [Flutter]
     ↕              ↕
[Security] ←→ [Firebase]
     ↕              ↕
    [Test]
```

**Coordination**:
- **Byzantine consensus** (fault-tolerant)
- Weighted voting
- Can tolerate agent failures
- Requires majority agreement

**Use cases**:
- Code reviews
- Approval decisions
- Quality gate evaluations

## 🧠 Intelligence & Learning

### RuVector Knowledge Store

**What it stores**:
- Successful implementation patterns
- Common bug fixes
- Architecture decisions
- Code review feedback

**How it helps**:
- 150x-12,500x faster retrieval vs naive search
- Agents learn from past successes
- Reduces redundant decision-making
- Improves cost efficiency

**Location**: `.claude-flow/vector_store/`

### Q-Learning Router

**What it does**:
- Routes tasks to best agent
- Learns from success/failure
- Optimizes for cost and quality

**Metrics**:
- Task completion time
- Quality metrics (test pass rate)
- Cost per task
- Agent specialization match

### Cost Optimization

**Target**: 30-50% reduction vs single-agent

**Strategies**:
1. **Intelligent routing**: Right agent for right task
2. **Task decomposition**: Parallel execution
3. **Context sharing**: Reduced redundancy
4. **Learning**: Avoid repeated mistakes

## 🔒 Security Configuration

### Restricted Paths
```yaml
- .env, .env.*
- **/*.key, **/*.pem
- **/secrets/**
- firebase-adminsdk-*.json
```

### AI Defence
- Injection prevention (SQL, NoSQL, command)
- Path traversal blocking
- Strict input validation

### Security Agent Triggers
- Any auth-related changes
- Firestore rules modifications
- User input handling code
- External API integrations

## 📊 Quality Enforcement

### Code Metrics (Enforced by Architect)
```yaml
max_lines_per_file: 500
max_lines_per_function: 50
min_test_coverage: 0.8
critical_path_coverage: 0.9
```

### Architectural Standards
```yaml
principles:
  - SOLID (mandatory)
  - Dependency Injection (mandatory)
  - Single Source of Truth
  - KISS (Keep It Simple)
  - SLAP (Single Level of Abstraction)

anti_patterns:
  - Band-aid fixes (auto-reject)
  - God objects
  - Circular dependencies
  - Type conditionals (use polymorphism)
```

### Testing Standards (Enforced by Test Specialist)
```yaml
patterns:
  - AAA (Arrange, Act, Assert)
  - One assertion per test
  - Descriptive test names
  - Mock external dependencies
  - Independent, isolated tests

coverage_gates:
  overall: 80%
  critical_paths: 90%
  new_code: 85%
```

## 🔌 MCP Integration

### How It Works

1. **MCP Server starts** when Claude Code launches
2. **Agents register** their capabilities
3. **Workflows** become available as tools
4. **Vector store** loads project knowledge

### Available in Claude Code

**Direct agent invocation**:
```
"Use the flutter specialist to optimize GameBoard"
```

**Workflow execution**:
```
"Run the feature development workflow for multiplayer mode"
```

**Swarm coordination**:
```
"Launch the feature team swarm to refactor authentication"
```

**Context-aware**:
- Agents know project structure
- Domain-specific knowledge loaded
- Past patterns available

## 🛠️ Customization

### Adding New Agent

1. Create `agents/new_agent.yaml`
2. Define expertise, capabilities, constraints
3. Add to swarm configurations
4. Update domain assignments
5. Rebuild vector store

### Adding New Workflow

1. Create `workflows/new_workflow.yaml`
2. Define phases and agent assignments
3. Configure consensus requirements
4. Set success criteria
5. Add failure handling

### Modifying Domain

1. Update `domains/domain_name.yaml`
2. Adjust layer structure
3. Update dependency rules
4. Modify agent assignments
5. Update quality gates

## 📈 Monitoring & Metrics

### Available Metrics

```bash
# View all metrics
npm run metrics

# Metrics tracked:
- Agent performance
- Task completion time
- Consensus rounds
- Cost per task
- Success/failure rates
- Coverage trends
```

### Health Checks

```bash
# Full health check
npm run health

# Checks:
- Agent availability
- Vector store status
- Configuration validity
- Swarm health
```

### Logs

**Location**: `logs/claude-flow.log`

**Format**: Structured JSON
```json
{
  "timestamp": "2026-01-26T12:34:56.789Z",
  "level": "info",
  "service": "claude-flow",
  "event": "consensus_reached",
  "context": {
    "swarm": "feature_team",
    "algorithm": "raft",
    "duration_ms": 1234,
    "participants": ["architect", "flutter_specialist", "firebase_specialist"]
  }
}
```

## 🚀 Best Practices

### 1. Use Workflows for Multi-Phase Tasks
```bash
# Bad: Manual coordination
--agent flutter_specialist --task "part 1"
--agent firebase_specialist --task "part 2"
--agent test_specialist --task "part 3"

# Good: Use workflow
--workflow feature_development --task "complete feature"
```

### 2. Trust Quality Gates
Don't bypass or override. If rejected, fix the issue.

### 3. Let Swarms Coordinate
Don't micromanage agent interactions. Let consensus algorithms work.

### 4. Review Metrics Regularly
```bash
npm run metrics
```
Learn from patterns, optimize for cost.

### 5. Keep Domains Clean
Maintain clear boundaries between Flutter, Firebase, and Testing domains.

## 🔄 Continuous Improvement

### Vector Store Maintenance
```bash
# Rebuild after major changes
npm run vector:rebuild
```

### Agent Tuning
- Review agent performance in metrics
- Adjust expertise domains
- Modify consensus thresholds

### Workflow Optimization
- Analyze phase durations
- Adjust consensus requirements
- Optimize parallel execution

---

**Questions?** Check [README.md](README.md) or [QUICK_START.md](QUICK_START.md)
