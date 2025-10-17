# How to Create Claude Code Agents

**Last Updated:** 2025-10-17
**Claude Code Version:** Latest (2025)

This guide covers everything you need to know about creating custom agents for Claude Code, including YAML formatting, tool permissions, and model selection.

---

## Table of Contents

1. [Overview](#overview)
2. [Agent File Format](#agent-file-format)
3. [Storage Locations](#storage-locations)
4. [YAML Configuration Fields](#yaml-configuration-fields)
5. [Model Selection](#model-selection)
6. [Tool Permissions](#tool-permissions)
7. [Complete Examples](#complete-examples)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)
10. [References](#references)

---

## Overview

Claude Code agents (also called sub-agents) are specialized AI assistants with their own instructions, context windows, and tool permissions. Agents are defined using Markdown files with YAML frontmatter.

**Key Benefits:**
- **Specialization** - Agents focused on specific tasks (testing, code review, refactoring)
- **Model Optimization** - Use fast Haiku for simple tasks, powerful Sonnet for complex work
- **Tool Control** - Restrict which tools each agent can access
- **Context Management** - Each agent maintains its own context window

> **Source:** [Claude Code Sub-agents Documentation](https://docs.claude.com/en/docs/claude-code/sub-agents)

---

## Agent File Format

Agents are Markdown files with YAML frontmatter followed by the system prompt:

```yaml
---
name: agent-name
description: When to use this agent
model: haiku
tools: Read, Write, Bash
---

Your detailed system prompt goes here.
This is what the agent will see as its instructions.
```

**File Extension:** `.yaml` or `.md` (both work)

> **Source:** [ClaudeLog Custom Agents Guide](https://claudelog.com/mechanics/custom-agents/)

---

## Storage Locations

### Global Agents
**Path:** `~/.claude/agents/`

Agents here are available across ALL projects.

```bash
~/.claude/agents/
  ├── code-reviewer.yaml
  ├── test-specialist.yaml
  └── documentation.yaml
```

### Project-Specific Agents
**Path:** `.claude/agents/` (in project root)

Agents here are only available in this project.

```bash
/my-project/.claude/agents/
  ├── db-migration.yaml
  ├── api-tester.yaml
  └── deployment.yaml
```

**Recommendation:** Use project-specific agents for domain-specific tasks, global agents for general-purpose tasks.

> **Source:** [Claude Code Sub-agents Documentation](https://docs.claude.com/en/docs/claude-code/sub-agents)

---

## YAML Configuration Fields

### Required Fields

#### `name`
**Type:** String
**Purpose:** Unique identifier for the agent

```yaml
name: test-specialist
```

**Rules:**
- Use lowercase with hyphens
- Must be unique (no duplicates)
- Descriptive of agent's purpose

#### `description`
**Type:** String
**Purpose:** Tells the main agent when to invoke this sub-agent

```yaml
description: RSpec test specialist for comprehensive test coverage following TDD principles
```

**Best Practices:**
- Be specific about when to use
- Include keywords the main agent will look for
- Keep under 200 characters

### Optional Fields

#### `model`
**Type:** String
**Purpose:** Specify which Claude model the agent uses

**Options:**
- `claude-sonnet-4-5-20250929` - Latest Sonnet (most capable)
- `claude-haiku-4-5-20251001` - Latest Haiku (fastest, most efficient)
- `sonnet` - Alias for latest Sonnet
- `haiku` - Alias for latest Haiku
- `opus` - Alias for latest Opus (if available)
- `inherit` - Use same model as main conversation
- Omit field - Uses default model configured for sub-agents

```yaml
# Explicit model version
model: claude-haiku-4-5-20251001

# Model alias
model: haiku

# Inherit from main conversation
model: inherit
```

**Model Selection Guide:**

| Model | Best For | Speed | Cost | Context |
|-------|----------|-------|------|---------|
| **Haiku 4.5** | Fast execution, simple tasks, testing, linting | ⚡⚡⚡ | 💰 | 200K |
| **Sonnet 4.5** | Complex reasoning, planning, code review | ⚡⚡ | 💰💰 | 200K |
| **Opus** | Most complex analysis, critical decisions | ⚡ | 💰💰💰 | 200K |

**Recommendations:**
- **Testing Agent** → Haiku 4.5 (fast, follows patterns)
- **Code Review Agent** → Sonnet 4.5 (needs reasoning)
- **Architecture Planning** → Sonnet 4.5 or Opus
- **Linting/Formatting** → Haiku 4.5 (simple rules)
- **Refactoring Agent** → Sonnet 4.5 (complex changes)

> **Sources:**
> [Claude Haiku 4.5 Announcement](https://www.anthropic.com/news/claude-haiku-4-5)
> [Claude Code Model Configuration](https://support.claude.com/en/articles/11940350-claude-code-model-configuration)

#### `tools`
**Type:** Comma-separated string
**Purpose:** Restrict which tools the agent can access

```yaml
# Specific tools only
tools: Read, Grep, Glob

# All tools (default if omitted)
# Just omit the tools field
```

**Available Tools:**
- `Read` - Read file contents
- `Write` - Create new files
- `Edit` - Modify existing files
- `MultiEdit` - Edit multiple files at once
- `Grep` - Search file contents
- `Glob` - Find files by pattern
- `Bash` - Execute shell commands
- `WebFetch` - Fetch URLs
- `WebSearch` - Search the web
- `Task` - Launch sub-agents

**Tool Patterns (Advanced):**

```yaml
# Allow specific file patterns
tools: Read, Write(src/**), Edit(test/**)

# Allow specific bash commands
tools: Read, Bash(git *), Bash(npm *)

# Deny dangerous operations
tools: Read, Write, Bash(!rm *), Bash(!sudo *)
```

**Default Behavior:** If `tools` field is omitted, agent inherits ALL tools from main thread (including MCP tools).

> **Sources:**
> [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
> [How to Use Allowed Tools](https://www.instructa.ai/blog/claude-code/how-to-use-allowed-tools-in-claude-code)

#### `system_prompt`
**Type:** Multi-line string (in YAML) OR markdown content (after frontmatter)
**Purpose:** The instructions the agent receives

**Option 1: YAML Field**
```yaml
---
name: test-agent
description: Testing specialist
model: haiku
system_prompt: |
  You are a testing specialist.
  Follow TDD principles.
  Write comprehensive tests.
---
```

**Option 2: Markdown Content** (Recommended)
```yaml
---
name: test-agent
description: Testing specialist
model: haiku
---

You are a testing specialist.

## Your Mission
Write comprehensive RSpec tests following TDD principles.

## Key Rules
- Test behavior not implementation
- One assertion per test
- Use realistic factories
```

**Best Practices:**
- Use markdown formatting for readability
- Include specific examples
- Reference key files/documentation
- Provide troubleshooting tips
- Keep under 4000 tokens (agent needs context space)

---

## Model Selection

### Available Models (2025)

#### Claude Sonnet 4.5
**Model ID:** `claude-sonnet-4-5-20250929`
**Alias:** `sonnet`

**Capabilities:**
- Most advanced reasoning and planning
- Best code understanding
- Complex refactoring
- Architecture decisions

**Use For:**
- Code review requiring deep analysis
- Complex refactoring tasks
- System design decisions
- Multi-file architectural changes

#### Claude Haiku 4.5
**Model ID:** `claude-haiku-4-5-20251001`
**Alias:** `haiku`

**Capabilities:**
- 3x faster than Sonnet
- 90% lower cost than Sonnet
- Excellent for well-defined tasks
- Matches Sonnet 3.5 quality on many benchmarks

**Use For:**
- Writing tests from patterns
- Running linters/formatters
- Simple CRUD operations
- Documentation generation
- Quick code fixes

**Performance Stats:**
- Speed: ~3 seconds for typical tasks
- Context: 200K tokens
- Quality: Comparable to Sonnet 3.5 for structured tasks

> **Source:** [Introducing Claude Haiku 4.5](https://www.anthropic.com/news/claude-haiku-4-5)

### Model Configuration Examples

```yaml
# Fast testing agent with explicit model version
---
name: test-specialist
description: Write RSpec tests
model: claude-haiku-4-5-20251001
---

# Code reviewer with alias
---
name: code-reviewer
description: Review code for quality and security
model: sonnet
---

# Inherit model from main conversation
---
name: quick-fixer
description: Fix linting errors
model: inherit
---

# Use default sub-agent model (no field)
---
name: docs-generator
description: Generate documentation
# model field omitted - uses configured default
---
```

---

## Tool Permissions

### Permission Levels

#### 1. **Full Access** (Default)
Omit `tools` field - agent gets all main thread tools

```yaml
---
name: full-access-agent
description: Can use any tool
# No tools field = full access
---
```

#### 2. **Read-Only Access**
Safe for exploration and analysis

```yaml
---
name: explorer
description: Explore and analyze codebase
tools: Read, Grep, Glob
---
```

#### 3. **Read + Write**
Can make changes but not execute commands

```yaml
---
name: code-modifier
description: Modify code files
tools: Read, Write, Edit, MultiEdit, Grep, Glob
---
```

#### 4. **Full Development Access**
Can read, write, and execute commands

```yaml
---
name: developer
description: Full development capabilities
tools: Read, Write, Edit, Grep, Glob, Bash
---
```

### Pattern-Based Permissions

Restrict tools to specific file patterns or commands:

```yaml
---
name: safe-developer
description: Developer with safety restrictions
tools: >
  Read,
  Write(src/**),
  Edit(test/**),
  Bash(git *),
  Bash(npm test),
  Bash(npm run lint),
  Bash(!rm *),
  Bash(!sudo *)
---
```

**Pattern Syntax:**
- `Write(path/pattern)` - Only write to matching paths
- `Bash(command pattern)` - Only run matching commands
- `Bash(!pattern)` - Explicitly deny matching commands
- `**` - Matches any subdirectory
- `*` - Matches any characters

### Security Best Practices

✅ **DO:**
- Use read-only tools for analysis agents
- Restrict write access to specific directories
- Whitelist allowed bash commands
- Test agents with minimal permissions first

❌ **DON'T:**
- Give bash access unless necessary
- Allow write access to config files
- Use `--dangerously-skip-permissions` in production
- Grant sudo access

**Example: Secure Testing Agent**
```yaml
---
name: test-specialist
description: Testing specialist (read-only + test execution)
model: haiku
tools: Read, Grep, Glob, Bash(bundle exec rspec *)
---
```

> **Sources:**
> [Claude Code Permissions Guide](https://www.eesel.ai/blog/claude-code-permissions)
> [How to Update Claude Code Permissions](https://claudelog.com/faqs/how-to-update-claude-code-permissions/)

---

## Complete Examples

### Example 1: Fast Testing Agent (Haiku)

**File:** `.claude/agents/test-specialist.yaml`

```yaml
---
name: test-specialist
description: RSpec test specialist for comprehensive test coverage following TDD principles
model: claude-haiku-4-5-20251001
tools: Read, Grep, Glob, Write(spec/**), Edit(spec/**), Bash(bundle exec rspec *)
---

You are a Test Specialist for Rails applications.

## Your Mission
Write comprehensive RSpec tests following TDD principles and the project's testing roadmap.

## Key Files
- **Roadmap:** docs/planning/TESTING_ROADMAP.md
- **Models:** app/models/
- **Factories:** test/factories/
- **Specs:** spec/

## Test Pattern (AAA)
```ruby
it 'validates email format' do
  # Arrange
  user = build(:user, email: 'invalid')

  # Act
  user.valid?

  # Assert
  expect(user.errors[:email]).to include('is invalid')
end
```

## Workflow
1. Pick next unchecked test from roadmap
2. Read actual model implementation
3. Write comprehensive tests
4. Run: `bundle exec rspec spec/models/user_spec.rb`
5. Fix failures immediately
6. Update roadmap with [x]

**Start with highest priority unchecked tests.**
```

### Example 2: Code Review Agent (Sonnet)

**File:** `.claude/agents/code-reviewer.yaml`

```yaml
---
name: code-reviewer
description: Expert code review specialist for quality, security, and best practices
model: claude-sonnet-4-5-20250929
tools: Read, Grep, Glob, Bash(git diff *), Bash(git log *)
---

You are an Expert Code Reviewer.

## Review Checklist

### Code Quality
- [ ] Follows project conventions
- [ ] No code duplication
- [ ] Proper error handling
- [ ] Clear variable names
- [ ] Adequate comments

### Security
- [ ] No SQL injection vulnerabilities
- [ ] Proper input validation
- [ ] No hardcoded secrets
- [ ] CSRF protection present
- [ ] XSS prevention

### Performance
- [ ] No N+1 queries
- [ ] Efficient algorithms
- [ ] Proper indexing
- [ ] Caching where appropriate

### Testing
- [ ] Adequate test coverage
- [ ] Edge cases tested
- [ ] Tests are maintainable

## Output Format
Provide review as structured markdown with severity levels:
- 🔴 CRITICAL - Security/data loss issues
- 🟡 WARNING - Performance/maintainability concerns
- 🟢 SUGGESTION - Nice-to-have improvements

Include specific file:line references.
```

### Example 3: Documentation Generator (Haiku)

**File:** `.claude/agents/docs-generator.yaml`

```yaml
---
name: docs-generator
description: Generate and update project documentation
model: haiku
tools: Read, Grep, Glob, Write(docs/**), Edit(docs/**), Write(README.md)
---

You are a Documentation Specialist.

## Your Responsibilities
1. Generate API documentation from code
2. Update README files
3. Create usage examples
4. Maintain changelog
5. Write inline code comments

## Documentation Standards
- Use markdown format
- Include code examples
- Add table of contents for long docs
- Keep language clear and concise
- Update timestamps

## Key Files
- README.md - Project overview
- docs/ - Detailed documentation
- CHANGELOG.md - Version history
- API.md - API reference

Generate comprehensive, accurate documentation.
```

### Example 4: Database Migration Agent (Sonnet)

**File:** `.claude/agents/db-migration.yaml`

```yaml
---
name: db-migration
description: Create and manage database migrations safely
model: sonnet
tools: Read, Write(db/migrate/**), Bash(rails generate migration *), Bash(rails db:migrate), Bash(rails db:rollback)
---

You are a Database Migration Specialist.

## Migration Rules
1. **Always reversible** - Define `up` and `down` methods
2. **Data safety** - Never delete columns with data
3. **Indexing** - Add indexes for foreign keys
4. **Default values** - Specify defaults for NOT NULL columns
5. **Timestamps** - Use Rails conventions

## Migration Checklist
- [ ] Migration is reversible
- [ ] Indexes added for new foreign keys
- [ ] NOT NULL columns have defaults or data migration
- [ ] Migration tested in development
- [ ] Rollback tested
- [ ] No destructive changes without confirmation

## Workflow
1. Analyze schema changes needed
2. Generate migration: `rails generate migration AddColumnToTable`
3. Edit migration file with proper up/down
4. Test: `rails db:migrate && rails db:rollback && rails db:migrate`
5. Update schema documentation

**Never deploy destructive migrations without explicit confirmation.**
```

---

## Best Practices

### 1. Name Agents Clearly
```yaml
# Good
name: test-specialist
name: code-reviewer
name: api-docs-generator

# Bad
name: agent1
name: helper
name: bot
```

### 2. Write Specific Descriptions
```yaml
# Good
description: RSpec test specialist for Rails models following TDD principles

# Bad
description: Testing agent
```

The main agent uses descriptions to decide when to invoke sub-agents. Be specific!

### 3. Choose the Right Model
```yaml
# Fast, simple tasks → Haiku
model: haiku  # For testing, linting, simple refactoring

# Complex analysis → Sonnet
model: sonnet  # For code review, architecture decisions

# Same as main → Inherit
model: inherit  # For consistency with main conversation
```

### 4. Restrict Tools Appropriately
```yaml
# Read-only for analysis
tools: Read, Grep, Glob

# Write access for code changes
tools: Read, Write, Edit, Grep, Glob

# Bash only when needed
tools: Read, Write, Bash(npm test), Bash(git *)
```

### 5. Provide Context in System Prompt
```yaml
system_prompt: |
  You are a Testing Specialist.

  ## Key Files
  - Roadmap: docs/testing/ROADMAP.md
  - Models: app/models/
  - Specs: spec/

  ## Important Rules
  - Multi-tenancy: Always test org scoping
  - Factories: Use test/factories/ not spec/factories/

  ## Workflow
  1. Read roadmap
  2. Pick next test
  3. Write tests
  4. Run tests
  5. Update roadmap
```

### 6. Test Your Agents

Create a test conversation to verify agent behavior:

```bash
# In Claude Code
/agent test-specialist

# Or
"Use the test-specialist agent to write User model tests"
```

Verify:
- Agent uses correct model
- Respects tool restrictions
- Follows system prompt
- Produces expected output

### 7. Version Control Your Agents

```bash
# Commit project agents
git add .claude/agents/
git commit -m "Add test-specialist agent"

# Backup global agents
cp -r ~/.claude/agents ~/backups/claude-agents-$(date +%Y%m%d)
```

### 8. Organize by Purpose

```
.claude/agents/
  ├── testing/
  │   ├── rspec-specialist.yaml
  │   ├── system-tester.yaml
  │   └── performance-tester.yaml
  ├── review/
  │   ├── code-reviewer.yaml
  │   └── security-reviewer.yaml
  └── docs/
      ├── api-docs.yaml
      └── readme-generator.yaml
```

> **Source:** [Practical Guide to Claude Code Sub-Agents](https://jewelhuq.medium.com/practical-guide-to-mastering-claude-codes-main-agent-and-sub-agents-fd52952dcf00)

---

## Troubleshooting

### Agent Not Being Invoked

**Problem:** Main agent doesn't use your sub-agent

**Solutions:**
1. **Check description** - Make it more specific with keywords
2. **Ask explicitly** - "Use the test-specialist agent"
3. **Check file location** - Must be in `.claude/agents/` or `~/.claude/agents/`
4. **Restart Claude Code** - Reload agent definitions

### Tool Permission Errors

**Problem:** Agent can't access files or run commands

**Solutions:**
1. **Check tools field** - Did you grant necessary tools?
2. **Check patterns** - Tool path patterns must match actual paths
3. **Grant permissions** - Claude Code may ask for permission first time

```yaml
# If agent needs to write tests
tools: Write(spec/**), Edit(spec/**)

# If agent needs to run tests
tools: Bash(bundle exec rspec *)
```

### Model Not Available

**Problem:** `Error: Model not available`

**Solutions:**
1. **Check model ID** - Use correct version ID
2. **Use alias** - Try `haiku` or `sonnet` instead of full ID
3. **Remove model field** - Use default model
4. **Check subscription** - Ensure you have access to that model

```yaml
# Try this instead
model: haiku  # Alias works better than full ID
```

### Agent Too Slow

**Problem:** Agent takes too long to respond

**Solutions:**
1. **Switch to Haiku** - 3x faster for most tasks
2. **Reduce prompt size** - Keep system prompt under 2000 tokens
3. **Limit tools** - Fewer tools = faster decisions
4. **Split into smaller agents** - One focused task per agent

```yaml
# Fast configuration
model: haiku
tools: Read, Write, Edit  # Only essential tools
```

### Agent Not Following Instructions

**Problem:** Agent doesn't follow system prompt

**Solutions:**
1. **Be more explicit** - Add step-by-step instructions
2. **Use examples** - Show exactly what you want
3. **Add rules** - Use bullet points and checklists
4. **Test prompt** - Try prompt in main conversation first

```yaml
system_prompt: |
  ## CRITICAL RULES (DO NOT SKIP)
  1. ALWAYS test multi-tenant scoping
  2. NEVER use hard-coded IDs in factories
  3. MUST update roadmap with [x] when complete

  ## Workflow (FOLLOW EXACTLY)
  1. Read file X
  2. Write tests to file Y
  3. Run command Z
  4. Update file W
```

### YAML Parsing Errors

**Problem:** `Error parsing agent YAML`

**Common Issues:**
```yaml
# ❌ WRONG - Unquoted colon
description: Test: Write tests

# ✅ CORRECT - Quote strings with colons
description: "Test: Write tests"

# ❌ WRONG - Incorrect indentation
system_prompt: |
Wrong indentation
  Inconsistent spaces

# ✅ CORRECT - Consistent indentation
system_prompt: |
  Correct indentation
  Consistent spaces
```

**Solution:** Use YAML validator or check:
- Quotes around strings with special chars
- Consistent indentation (2 spaces)
- Proper multi-line syntax (` |`)

---

## References

### Official Documentation
- [Claude Code Sub-agents](https://docs.claude.com/en/docs/claude-code/sub-agents) - Official Anthropic documentation
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) - Engineering best practices from Anthropic
- [Claude Haiku 4.5 Announcement](https://www.anthropic.com/news/claude-haiku-4-5) - Model capabilities and benchmarks

### Community Guides
- [ClaudeLog Custom Agents Guide](https://claudelog.com/mechanics/custom-agents/) - Comprehensive community guide
- [Practical Guide to Sub-Agents](https://jewelhuq.medium.com/practical-guide-to-mastering-claude-codes-main-agent-and-sub-agents-fd52952dcf00) - Hands-on tutorial
- [Claude Code Complete Guide](https://www.siddharthbharath.com/claude-code-the-complete-guide/) - In-depth coverage

### Tool Configuration
- [How to Use Allowed Tools](https://www.instructa.ai/blog/claude-code/how-to-use-allowed-tools-in-claude-code) - Tool permission guide
- [Claude Code Permissions](https://www.eesel.ai/blog/claude-code-permissions) - Complete permissions guide
- [Update Claude Code Permissions](https://claudelog.com/faqs/how-to-update-claude-code-permissions/) - Permission troubleshooting

### Model Information
- [Claude Code Model Configuration](https://support.claude.com/en/articles/11940350-claude-code-model-configuration) - Model selection guide
- [Access Claude Haiku 4.5](https://skywork.ai/blog/how-to-access-claude-haiku-4-5-guide/) - Haiku 4.5 access guide

### Advanced Topics
- [Claude Code Cheatsheet](https://shipyard.build/blog/claude-code-cheat-sheet/) - CLI commands and config
- [Building Agents with SDK](https://blog.promptlayer.com/building-agents-with-claude-codes-sdk/) - Programmatic agent creation
- [Agent System Overview](https://github.com/ruvnet/claude-flow/wiki/Agent-System-Overview) - Advanced patterns

---

## Model Version Reference

### Current Models (2025)

| Model | Version ID | Alias | Speed | Cost | Best For |
|-------|-----------|-------|-------|------|----------|
| Sonnet 4.5 | claude-sonnet-4-5-20250929 | `sonnet` | ⚡⚡ | 💰💰 | Complex reasoning, code review |
| Haiku 4.5 | claude-haiku-4-5-20251001 | `haiku` | ⚡⚡⚡ | 💰 | Fast execution, testing, linting |
| Opus 3 | claude-opus-3-20240229 | `opus` | ⚡ | 💰💰💰 | Most complex analysis |

**Note:** Always use model aliases (`haiku`, `sonnet`) instead of version IDs for automatic updates to latest version.

---

## Quick Start Checklist

- [ ] Create `.claude/agents/` directory in your project
- [ ] Create agent YAML file with frontmatter
- [ ] Set `name` (unique identifier)
- [ ] Set `description` (when to invoke)
- [ ] Set `model` (haiku for speed, sonnet for complex)
- [ ] Set `tools` (grant minimum necessary permissions)
- [ ] Write detailed `system_prompt`
- [ ] Test agent: `/agent agent-name`
- [ ] Verify agent behavior matches expectations
- [ ] Commit to version control

---

**Happy agent building! 🤖**

For questions or issues, refer to the [official Claude Code documentation](https://docs.claude.com/en/docs/claude-code/sub-agents).
