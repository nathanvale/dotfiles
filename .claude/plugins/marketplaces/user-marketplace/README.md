# User Domain Marketplace

Your personal plugin marketplace for developing and managing custom Claude Code plugins.

## Structure

```
user-marketplace/
├── .claude-plugin/
│   └── marketplace.json     # Marketplace manifest
├── plugins/                  # Your plugins directory
│   └── task-streams/        # Existing plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── commands/
│       ├── skills/
│       └── ...
└── README.md                # This file
```

## Adding This Marketplace to Claude Code

Run this command in Claude Code:

```shell
/plugin marketplace add ~/.claude/plugins/user-marketplace
```

## Managing Plugins

### Install a plugin from this marketplace
```shell
/plugin install task-streams@user-marketplace
```

### Uninstall a plugin
```shell
/plugin uninstall task-streams@user-marketplace
```

### Update after making changes
```shell
/plugin uninstall task-streams@user-marketplace
/plugin install task-streams@user-marketplace
```

## Creating a New Plugin

1. Create a new plugin directory:
```bash
mkdir -p ~/.claude/plugins/user-marketplace/plugins/my-new-plugin
cd ~/.claude/plugins/user-marketplace/plugins/my-new-plugin
```

2. Create the plugin structure:
```bash
mkdir -p .claude-plugin commands skills agents hooks
```

3. Create the plugin manifest:
```bash
cat > .claude-plugin/plugin.json << 'EOF'
{
  "name": "my-new-plugin",
  "version": "1.0.0",
  "description": "Description of your plugin",
  "author": {
    "name": "Nathan Vale"
  }
}
EOF
```

4. Add your components (commands, skills, agents, hooks)

5. Update the marketplace manifest:
```bash
# Edit ~/.claude/plugins/user-marketplace/.claude-plugin/marketplace.json
# Add your new plugin to the "plugins" array
```

6. Install and test:
```shell
/plugin install my-new-plugin@user-marketplace
```

## Plugin Components

### Commands (`commands/`)
Markdown files that define slash commands.

### Skills (`skills/`)
Agent capabilities that Claude can invoke autonomously.

### Agents (`agents/`)
Specialized sub-agents for specific tasks.

### Hooks (`hooks/`)
Event handlers that respond to Claude Code events.

## Quick Reference

- **List all plugins**: `/plugin`
- **Browse available**: Browse Plugins in the `/plugin` menu
- **Check installation**: `/help` (shows all available commands)
- **View marketplaces**: Manage Marketplaces in `/plugin` menu

## Development Workflow

1. Make changes to your plugin files
2. Uninstall the old version: `/plugin uninstall <name>@user-marketplace`
3. Reinstall: `/plugin install <name>@user-marketplace`
4. Test your changes
5. Repeat as needed

## Tips

- Keep your plugins modular and focused
- Test each component individually
- Use semantic versioning in plugin.json
- Document your commands and skills clearly
- Commit your marketplace to git for backup
