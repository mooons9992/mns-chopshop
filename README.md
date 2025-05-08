# MNS ChopShop
A feature-rich vehicle chopshop system for FiveM servers running QBCore/QBox frameworks.

## Features
- **Sell Stolen Vehicles**: Sell non-owned vehicles for cash rewards based on vehicle class and condition
- **Mission System**: Take on missions to steal specific vehicles for larger rewards
- **Multi-Framework Support**: Compatible with both QBCore and OX components
- **Dynamic Vehicle Value**: Vehicle rewards calculated based on performance stats and damage
- **Anti-Exploit Mechanisms**: Prevents players from selling owned vehicles or exploiting the system
- **Performance Optimized**: Minimally impacts server performance

## Dependencies
- QBCore or QBox framework
- oxmysql
- Target system (supports both ox_target and qb-target)
- Fuel system (supports LegacyFuel, cdn-fuel, lc_fuel, and ps-fuel)

## Installation
1. Download the latest release
2. Extract to your resources folder
3. Add `ensure mns-chopshop` to your server.cfg
4. Configure the settings in config.lua

## Usage

### Sell Stolen Vehicles
1. Find or steal a vehicle that isn't player-owned
2. Drive it to the chopshop NPC
3. Interact with the NPC using the target system
4. Receive a cash reward based on the vehicle's condition and class

### Complete Missions
1. Talk to the chopshop NPC to start a mission
2. Locate and steal the specified vehicle
3. Return it to the chopshop for a reward
4. Complete the mission before the timeout expires

## Configuration
The script includes extensive configuration options:

- UI framework selection (QBCore, OX, or custom)
- Notification templates and messaging
- Reward calculations and multipliers
- Vehicle spawn locations and models
- NPC appearance and positioning

## Framework Compatibility
MNS ChopShop can work with different UI components:

```lua
Config.UI = {
   target = 'ox_target',    -- Options: 'ox_target', 'qb-target'
   fuel = 'lc_fuel',        -- Options: 'LegacyFuel', 'cdn-fuel', 'lc_fuel', 'ps-fuel'
   notify = 'qb',           -- Options: 'qb', 'ox', 'esx', 'custom'
   inventory = 'qb',        -- Options: 'qb', 'ox_inventory', 'qs-inventory'
   menu = 'ox',             -- Options: 'qb', 'ox', 'nh-context'
   progressbar = 'ox',      -- Options: 'qb', 'ox'
}
```

## Admin Commands
- `/forcechopshop` - Force start a chopshop mission (Admin only)

## Version History
### 1.0.0
- Initial release
- Multi-framework support
- Dynamic vehicle value calculation
- Mission system with random vehicles
- Version checker

## Support
For support or questions about this script or other scripts, join our Discord server: [Join Discord](https://discord.gg/yourlink)