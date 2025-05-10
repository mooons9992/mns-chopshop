# MNS ChopShop

A feature-rich vehicle chopshop system for FiveM servers running QBCore/QBox frameworks.

## Features

- **Stolen Vehicle Missions**: Complete missions to find and deliver stolen vehicles for cash rewards
- **Search & Find System**: Vehicles spawn in a radius area - you need to search to find them
- **Time Pressure**: 5-minute time limit to find and deliver the vehicle before it breaks down
- **Vehicle Variety**: 30+ different vehicle models that can appear in missions
- **Dynamic Rewards**: Payment based on vehicle class, condition, and damage
- **Random Vehicle Condition**: Each vehicle has randomized damage, fuel levels, and appearance
- **Multi-Framework Support**: Compatible with both QBCore and OX components

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

### Complete Chopshop Missions
1. Talk to the chopshop NPC at Hayes Auto to start a mission
2. A radius circle will appear on your map showing the general area where the vehicle is located
3. Search within the radius to find the vehicle (the exact vehicle location is not marked)
4. Once you find and enter the vehicle, a delivery marker will appear
5. Deliver the vehicle to the dropoff location within the time limit (default: 5 minutes)
6. Receive a cash reward based on the vehicle's class and condition

## Configuration

The script includes extensive configuration options:

```lua
-- Mission system configuration
Config.Mission = {
   Radius = 100.0,       -- Search area radius for finding the vehicle
   Cooldown = 300,       -- Time between missions in seconds
   TimeLimit = 300,      -- Time limit to deliver the vehicle in seconds (5 minutes)
   
   -- Vehicle models that can appear in missions (30+ options)
   VehicleModels = {
      -- Supercars
      "zentorno",       -- Pegassi Zentorno
      "adder",          -- Truffade Adder
      -- And many more...
   },
   
   -- Random spawn locations around the city
   SpawnLocations = {
      -- Downtown
      vector4(286.63, -1036.36, 29.07, 89.83),
      -- La Mesa
      vector4(948.59, -1698.46, 29.65, 82.71),
      -- And more locations...
   }
}
```

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

## Vehicle Features

- **Dynamic Damage System**: Vehicles spawn with randomized engine and body damage
- **Random Appearance**: Includes random dirt levels, broken windows or doors
- **Variable Fuel Levels**: Each vehicle has a different amount of fuel (20-80%)
- **Vehicle Classes**: Reward multipliers based on vehicle class (supercars pay more than sedans)

## Support

For support or questions about this script or other scripts, join our [Discord server](https://discord.gg/example)