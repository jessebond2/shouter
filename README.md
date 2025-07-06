# WoW Classic Addons Repository

This repository contains World of Warcraft Classic addons, starting with **Shouter**.

## Shouter Addon

Shouter is a WoW Classic addon that automatically yells when specified players get within a certain distance of you. Perfect for PvP situations, rare spawn camping, or just keeping track of friends!

### Features

- Track specific player names
- Configurable detection range (default: 30 yards)
- Cooldown system to prevent spam (default: 60 seconds per player)
- Simple slash commands for configuration
- Persistent settings saved between sessions

### Installation

1. Download the `Addons/Shouter` folder
2. Copy it to your WoW Classic addons directory:
   - Windows: `C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns\`
   - Mac: `/Applications/World of Warcraft/_classic_/Interface/AddOns/`
3. Restart WoW or type `/reload` in-game

### Usage

#### Commands

- `/shouter` or `/shout` - Show help menu
- `/shouter add <name>` - Add a player to track
- `/shouter remove <name>` - Remove a tracked player
- `/shouter list` - List all tracked players
- `/shouter range <number>` - Set detection range in yards (default: 30)
- `/shouter cooldown <number>` - Set yell cooldown in seconds (default: 60)
- `/shouter enable` - Enable the addon
- `/shouter disable` - Disable the addon
- `/shouter clear` - Remove all tracked players

#### Examples

```
/shouter add Ganker
/shouter add RareSpawnKiller
/shouter range 40
/shouter cooldown 30
```

### How It Works

The addon continuously scans nearby players in your party or raid. When a tracked player comes within the specified range, it will:
1. Yell a message visible to all nearby players
2. Print a notification in your chat window
3. Wait for the cooldown period before yelling about that player again

### Contributing

To add new addons to this repository:
1. Create a new folder under `Addons/YourAddonName/`
2. Include a `.toc` file with proper metadata
3. Follow WoW Classic API guidelines
4. Update this README with your addon's information