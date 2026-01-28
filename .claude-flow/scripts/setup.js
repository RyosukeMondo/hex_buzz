#!/usr/bin/env node

/**
 * Claude-Flow Setup Script for HexBuzz
 * Initializes claude-flow configuration and verifies setup
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const PROJECT_ROOT = path.join(__dirname, '../..');
const CLAUDE_FLOW_ROOT = path.join(PROJECT_ROOT, '.claude-flow');

console.log('🚀 Setting up Claude-Flow for HexBuzz...\n');

// Step 1: Verify directory structure
console.log('📁 Verifying directory structure...');
const requiredDirs = [
  'agents',
  'workflows',
  'domains',
  'swarms',
  'config',
  'vector_store'
];

requiredDirs.forEach(dir => {
  const dirPath = path.join(CLAUDE_FLOW_ROOT, dir);
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    console.log(`  ✓ Created ${dir}/`);
  } else {
    console.log(`  ✓ ${dir}/ exists`);
  }
});

// Step 2: Verify configuration files
console.log('\n📋 Verifying configuration files...');
const configFiles = {
  'config/claude-flow.yaml': 'Main configuration',
  'agents/flutter_specialist.yaml': 'Flutter specialist agent',
  'agents/firebase_specialist.yaml': 'Firebase specialist agent',
  'agents/test_specialist.yaml': 'Test specialist agent',
  'agents/security_specialist.yaml': 'Security specialist agent',
  'agents/architect.yaml': 'Architect agent',
  'workflows/feature_development.yaml': 'Feature development workflow',
  'workflows/bug_fix.yaml': 'Bug fix workflow',
  'workflows/code_review.yaml': 'Code review workflow',
  'domains/flutter_app.yaml': 'Flutter app domain',
  'domains/firebase_backend.yaml': 'Firebase backend domain',
  'domains/testing.yaml': 'Testing domain',
  'swarms/feature_team.yaml': 'Feature team swarm',
  'swarms/review_committee.yaml': 'Review committee swarm',
  'mcp-config.json': 'MCP server configuration'
};

let allFilesExist = true;
Object.entries(configFiles).forEach(([file, description]) => {
  const filePath = path.join(CLAUDE_FLOW_ROOT, file);
  if (fs.existsSync(filePath)) {
    console.log(`  ✓ ${description}`);
  } else {
    console.log(`  ✗ Missing: ${description} (${file})`);
    allFilesExist = false;
  }
});

if (!allFilesExist) {
  console.error('\n❌ Some configuration files are missing. Please ensure all files are created.');
  process.exit(1);
}

// Step 3: Check Node.js version
console.log('\n🔍 Checking Node.js version...');
const nodeVersion = process.version;
const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);
if (majorVersion >= 18) {
  console.log(`  ✓ Node.js ${nodeVersion} (>= 18.0.0)`);
} else {
  console.error(`  ✗ Node.js ${nodeVersion} is too old. Requires >= 18.0.0`);
  process.exit(1);
}

// Step 4: Verify project structure
console.log('\n🏗️  Verifying project structure...');
const projectDirs = [
  'lib',
  'functions',
  'test',
  'integration_test'
];

projectDirs.forEach(dir => {
  const dirPath = path.join(PROJECT_ROOT, dir);
  if (fs.existsSync(dirPath)) {
    console.log(`  ✓ ${dir}/ exists`);
  } else {
    console.log(`  ⚠ ${dir}/ not found (may be optional)`);
  }
});

// Step 5: Create .gitignore entries
console.log('\n📝 Updating .gitignore...');
const gitignorePath = path.join(PROJECT_ROOT, '.gitignore');
const gitignoreEntries = [
  '',
  '# Claude-Flow',
  '.claude-flow/vector_store/',
  '.claude-flow/logs/',
  '.claude-flow/.cache/',
  'logs/claude-flow.log'
];

if (fs.existsSync(gitignorePath)) {
  let gitignoreContent = fs.readFileSync(gitignorePath, 'utf8');

  if (!gitignoreContent.includes('# Claude-Flow')) {
    fs.appendFileSync(gitignorePath, gitignoreEntries.join('\n') + '\n');
    console.log('  ✓ Added Claude-Flow entries to .gitignore');
  } else {
    console.log('  ✓ .gitignore already contains Claude-Flow entries');
  }
} else {
  fs.writeFileSync(gitignorePath, gitignoreEntries.join('\n') + '\n');
  console.log('  ✓ Created .gitignore with Claude-Flow entries');
}

// Step 6: Summary
console.log('\n✅ Claude-Flow setup complete!\n');
console.log('📚 Next steps:');
console.log('  1. Install MCP server:');
console.log('     npm run mcp:install');
console.log('     (or manually: claude mcp add claude-flow -- npx -y claude-flow@v3alpha mcp start)');
console.log('');
console.log('  2. Verify agents:');
console.log('     npm run agent:list');
console.log('');
console.log('  3. Check workflows:');
console.log('     npm run workflow:list');
console.log('');
console.log('  4. Run health check:');
console.log('     npm run health');
console.log('');
console.log('📖 Documentation: .claude-flow/README.md');
console.log('');
