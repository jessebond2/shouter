# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a World of Warcraft Classic addon development repository. The project is structured to support multiple addons, with the first addon being "Shouter" - an addon that yells when specified players get within a certain distance.

## Repository Structure

```
/
├── Addons/              # Contains all WoW addons
│   └── Shouter/        # The Shouter addon
│       ├── Shouter.toc # Table of Contents file (addon metadata)
│       └── Shouter.lua # Main addon logic
└── CLAUDE.md           # This file
```

## WoW Addon Development Guidelines

### Interface Version
- Classic Era: 11500
- Classic Wrath: 30403
- Update the Interface number in .toc files accordingly

### File Structure for New Addons
When creating a new addon:
1. Create a new directory under `Addons/AddonName/`
2. Create `AddonName.toc` file with proper metadata
3. Create main Lua file(s) referenced in the .toc file

### Common WoW API Functions Used
- `UnitPosition()` - Get unit coordinates
- `UnitName()` - Get unit name
- `SendChatMessage()` - Send messages to chat
- `CreateFrame()` - Create UI frames
- `RegisterEvent()` - Register for game events

### Testing Addons
To test addons in WoW Classic:
1. Copy the addon folder to `World of Warcraft/_classic_/Interface/AddOns/`
2. Restart WoW or type `/reload` in-game
3. Check if addon loads with `/script print(IsAddOnLoaded("AddonName"))`

### SavedVariables
- Declared in .toc file with `## SavedVariables:`
- Automatically saved between sessions
- Initialize in ADDON_LOADED event

### Slash Commands
Register slash commands using:
```lua
SLASH_COMMANDNAME1 = "/command"
SlashCmdList["COMMANDNAME"] = function(msg) ... end
```