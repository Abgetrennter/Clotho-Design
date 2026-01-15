> 本文由 [简悦 SimpRead](http://ksria.com/simpread/) 转码， 原文地址 [docs.cline.bot](https://docs.cline.bot/features/cline-rules)

> Cline Rules allow you to provide Cline with system-level guidance. Think of them as a persistent way to include context and preferences for your projects or globally for every conversation.Cline 规则允许您为 Cline 提供系统层面的指导。

Cline Rules allow you to provide Cline with system-level guidance. Think of them as a persistent way to include context and preferences for your projects or globally for every conversation.  
Cline 规则允许您为 Cline 提供系统层面的指导。把它们看作是为你的项目或每次对话中整体性地包含上下文和偏好的持续方式。

Creating a Rule 制定规则
--------------------

You can create a rule by clicking the `+` button in the Rules tab. This will open a new file in your IDE which you can use to write your rule.  
你可以点击规则标签中的`+`按钮创建规则。这会在你的 IDE 中打开一个新文件，你可以用它来编写规则。

Once you save the file:  
保存文件后：

*   Your rule will be stored in the `.clinerules/` directory in your project (if it’s a Workspace Rule)  
    你的规则会存储在项目的`.clinerules/`目录中（如果是 Workspace Rule 的话）
*   Or in the Global Rules directory (if it’s a Global Rule):  
    或者在全局规则目录（如果是全局规则）：

### Global Rules Directory Location  
全局规则目录位置

The location of your Global Rules directory depends on your operating system:  
你的全局规则目录的位置取决于你的作系统：

<table><thead><tr><th>Operating System<kiss-translator> 操作系统</kiss-translator></th><th>Default Location<kiss-translator> 默认位置</kiss-translator></th><th>Notes<kiss-translator> 注释</kiss-translator></th></tr></thead><tbody><tr><td><strong>Windows</strong></td><td><code>Documents\Cline\Rules</code></td><td>Uses system Documents folder</td></tr><tr><td><strong>macOS</strong></td><td><code>~/Documents/Cline/Rules</code></td><td>Uses user Documents folder</td></tr><tr><td><strong>Linux/WSL</strong></td><td><code>~/Documents/Cline/Rules</code></td><td>May fall back to <code>~/Cline/Rules</code> on some systems</td></tr></tbody></table>

> **Note for Linux/WSL users**: If you don’t find your global rules in `~/Documents/Cline/Rules`, check `~/Cline/Rules` as the location may vary depending on your system configuration and whether the Documents directory exists.

You can also have Cline create a rule for you by using the [`/newrule` slash command](https://docs.cline.bot/features/slash-commands/new-rule) in the chat.

Example Cline Rule Structure

```
# Project Guidelines

## Documentation Requirements

-   Update relevant documentation in /docs when modifying features
-   Keep README.md in sync with new capabilities
-   Maintain changelog entries in CHANGELOG.md

## Architecture Decision Records

Create ADRs in /docs/adr for:

-   Major dependency changes
-   Architectural pattern changes
-   New integration patterns
-   Database schema changes
    Follow template in /docs/adr/template.md

## Code Style & Patterns

-   Generate API clients using OpenAPI Generator
-   Use TypeScript axios template
-   Place generated code in /src/generated
-   Prefer composition over inheritance
-   Use repository pattern for data access
-   Follow error handling pattern in /src/utils/errors.ts

## Testing Standards

-   Unit tests required for business logic
-   Integration tests for API endpoints
-   E2E tests for critical user flows
```

### Key Benefits

1.  **Version Controlled**: The `.clinerules` file becomes part of your project’s source code
2.  **Team Consistency**: Ensures consistent behavior across all team members
3.  **Project-Specific**: Rules and standards tailored to each project’s needs
4.  **Institutional Knowledge**: Maintains project standards and practices in code

Place the `.clinerules` file in your project’s root directory:

```
your-project/
├── .clinerules
├── src/
├── docs/
└── ...
```

Cline’s system prompt, on the other hand, is not user-editable ([here’s where you can find it](https://github.com/cline/cline/blob/main/src/core/prompts/system.ts)). For a broader look at prompt engineering best practices, check out [this resource](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview).

### AGENTS.md Standard Support

Cline also supports the [AGENTS.md](https://agents.md/) standard as a fallback (in addition to Cline Rules) by automatically detecting `AGENTS.md` files in your workspace root. This allows you to use the same rules file across different AI coding tools.

```
your-project/
├── AGENTS.md
├── src/
└── ...
```

### Tips for Writing Effective Cline Rules

*   Be Clear and Concise: Use simple language and avoid ambiguity.
*   Focus on Desired Outcomes: Describe the results you want, not the specific steps.
*   Test and Iterate: Experiment to find what works best for your workflow.

### .clinerules/ Folder System

```
your-project/
├── .clinerules/              # Folder containing active rules
│   ├── 01-coding.md          # Core coding standards
│   ├── 02-documentation.md   # Documentation requirements
│   └── current-sprint.md     # Rules specific to current work
├── src/
└── ...
```

Cline automatically processes **all Markdown files** inside the `.clinerules/` directory, combining them into a unified set of rules. The numeric prefixes (optional) help organize files in a logical sequence.

#### Using a Rules Bank

For projects with multiple contexts or teams, maintain a rules bank directory:

```
your-project/
├── .clinerules/              # Active rules - automatically applied
│   ├── 01-coding.md
│   └── client-a.md
│
├── clinerules-bank/          # Repository of available but inactive rules
│   ├── clients/              # Client-specific rule sets
│   │   ├── client-a.md
│   │   └── client-b.md
│   ├── frameworks/           # Framework-specific rules
│   │   ├── react.md
│   │   └── vue.md
│   └── project-types/        # Project type standards
│       ├── api-service.md
│       └── frontend-app.md
└── ...
```

#### Benefits of the Folder Approach

1.  **Contextual Activation**: Copy only relevant rules from the bank to the active folder
2.  **Easier Maintenance**: Update individual rule files without affecting others
3.  **Team Flexibility**: Different team members can activate rules specific to their current task
4.  **Reduced Noise**: Keep the active ruleset focused and relevant

#### Usage Examples

Switch between client projects:

```
# Switch to Client B project
rm .clinerules/client-a.md
cp clinerules-bank/clients/client-b.md .clinerules/
```

Adapt to different tech stacks:

```
# Frontend React project
cp clinerules-bank/frameworks/react.md .clinerules/
```

#### Implementation Tips

*   Keep individual rule files focused on specific concerns
*   Use descriptive filenames that clearly indicate the rule’s purpose
*   Consider git-ignoring the active `.clinerules/` folder while tracking the `clinerules-bank/`
*   Create team scripts to quickly activate common rule combinations

The folder system transforms your Cline rules from a static document into a dynamic knowledge system that adapts to your team’s changing contexts and requirements.

### Managing Rules with the Toggleable Popover

To make managing both single `.clinerules` files and the folder system even easier, Cline v3.13 introduces a dedicated popover UI directly accessible from the chat interface. Located conveniently under the chat input field, this popover allows you to:

*   **Instantly See Active Rules:** View which global rules (from your user settings) and workspace rules (`.clinerules` file or folder contents) are currently active.
*   **Quickly Toggle Rules:** Enable or disable specific rule files within your workspace `.clinerules/` folder with a single click. This is perfect for activating context-specific rules (like `react-rules.md` or `memory-bank.md`) only when needed.
*   **Easily Add/Manage Rules:** Quickly create a workspace `.clinerules` file or folder if one doesn’t exist, or add new rule files to an existing folder.

This UI significantly simplifies switching contexts and managing different sets of instructions without needing to manually edit files or configurations during a conversation.