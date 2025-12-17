# Survival Horror Mod - Bug Fix Status Report

## Date: December 17, 2025

## Overview

This document tracks the bugs identified, research conducted, and fixes implemented for the Left 4 Dead 2 Survival Horror mutation mod.

---

## Original Bug Reports

### Bug #1: Players Have Pistol
**Problem:** Players spawn with a pistol. Should have ONLY a hunting rifle with 20 total shots.

**Solution Implemented:**
- `SetupPlayerLoadout()` strips ALL weapons via `m_hMyWeapons` NetProp (slots 0-5)
- Gives hunting rifle, sets clip to 20 via `SetClip1()`
- Sets all reserve ammo to 0 via `NetProps.SetPropIntArray()`
- `OnGameEvent_ammo_pickup()` blocks ammo pickups by resetting reserve to 0

### Bug #2: Melee Weapons Too Strong
**Problem:** Melee weapons should require precision/skill to be effective.

**Research Finding:** Headshot-only for melee is NOT possible in VScript because the `Hitgroup` field in `AllowTakeDamage` is not populated for melee attacks (Source Engine limitation).

**Solution Implemented:**
- Tiered damage system with random multiplier (0.25 to 1.0)
- Tier 1 (katana, machete, fireaxe, chainsaw): 25%-100% damage
- Tier 2 (baseball bat, crowbar, etc.): 12.5%-50% damage  
- Tier 3 (frying pan, tonfa): 6.25%-25% damage

### Bug #3: Too Many Zombies
**Problem:** Default maps have too many zombies. Need to reduce and spread them out.

**Solution Implemented:**
- `CullZombiesToTarget(80)` removes zombies using cluster-aware algorithm
- Zombies scored by proximity (2m/4m/16m distances)
- Most clustered zombies removed first
- `z_common_limit = 80` prevents Director from spawning more
- `OnGameEvent_infected_spawn()` auto-culls if count exceeds 80

### Bug #4: AI Bots Should Be Blocked
**Problem:** Only human players should be allowed.

**Solution Implemented:**
- `KickAllSurvivorBots()` removes all AI survivor bots at round start
- `cm_NoSurvivorBots = true` in MutationOptions
- `sb_all_bot_game = 0` and `allow_all_bot_survivor_team = 0` cvars

---

## Audit Findings and Fixes

Two independent audits were conducted to identify implementation bugs. Below are the findings with evidence and resolution status.

### CRITICAL: Event System Not Working

**Issue:** `OnGameEvent_*` functions were defined but:
1. Not all were registered to roottable
2. `__CollectEventCallbacks()` was never called

**Evidence:** 
- `RegisterCallbacks()` only registered 5 callbacks, missing `OnGameEvent_round_start`, `OnGameEvent_player_spawn`, etc.
- Without `__CollectEventCallbacks()`, the engine doesn't know these functions are event handlers

**Fix Applied:**
```squirrel
// Added to RegisterCallbacks():
getroottable().OnGameEvent_round_start <- OnGameEvent_round_start
getroottable().OnGameEvent_player_spawn <- OnGameEvent_player_spawn
getroottable().OnGameEvent_player_incapacitated <- OnGameEvent_player_incapacitated
getroottable().OnGameEvent_round_start_post_nav <- OnGameEvent_round_start_post_nav
getroottable().OnGameEvent_player_first_spawn <- OnGameEvent_player_first_spawn

// Added to initialization:
__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)
```

**Status:** FIXED (lines 117-157, 978)

---

### CRITICAL: GetDefaultItem Returns Wrong Type

**Issue:** `GetDefaultItem()` returned `0` instead of `""` for non-rifle slots.

**Evidence:** In L4D2 VScript, returning `0` (integer) may not properly block a weapon slot. The engine expects:
- String classname to spawn that weapon
- Empty string `""` to explicitly block the slot
- `null` to use engine default

**Fix Applied:**
```squirrel
function GetDefaultItem(index)
{
    if (index == 0) return "hunting_rifle"
    return ""  // Block all other slots (pistol, etc.)
}
```

**Status:** FIXED (lines 616-623)

---

### HIGH: Bot Kick Used Player Name

**Issue:** `SendToServerConsole("kick " + ent.GetPlayerName())` could fail if names contain spaces or special characters.

**Research Evidence:** From Left4Lib source code, the correct approach is:
```squirrel
SendToServerConsole("kickid " + userid)
```
The `kickid` command uses numeric userid, not player name.

**Fix Applied:**
```squirrel
local userid = ent.GetPlayerUserId()
SendToServerConsole("kickid " + userid)
```

**Status:** FIXED (line 505)

---

### HIGH: FinalizePlayerAmmo Depended on Active Weapon

**Issue:** `FinalizePlayerAmmo()` used `player.GetActiveWeapon()` which could return wrong weapon if player switched.

**Fix Applied:** Now iterates through `m_hMyWeapons` slots to find hunting rifle:
```squirrel
for (local i = 0; i < 6; i++)
{
    local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
    if (weapon != null && weapon.IsValid() && weapon.GetClassname() == "weapon_hunting_rifle")
    {
        weapon.SetClip1(HUNTING_RIFLE_CLIP)
        break
    }
}
```

**Status:** FIXED (lines 455-476)

---

### MEDIUM: sv_cheats Unnecessarily Enabled

**Issue:** `sv_cheats = 1` was set, allowing players to use cheat commands.

**Research Evidence:** From Left4Lib source code, VScript's `Convars.SetValue()` has elevated privileges. The cvars used in this mod (director options, ammo limits, etc.) do NOT require `sv_cheats` when set via VScript.

**Fix Applied:** Removed `Convars.SetValue("sv_cheats", 1)` line.

**Status:** FIXED (lines 49-51 now contain explanatory comment only)

---

### DISPUTED: Ammo Pickup Doesn't Cap Clip

**Claim:** Some ammo piles directly refill clip, bypassing reserve-only clearing.

**Research Finding:** DISPUTED. In L4D2, `weapon_ammo_spawn` refills RESERVE ammo, not clip. The script already:
1. Clears reserve ammo in `OnGameEvent_ammo_pickup()`
2. Blocks `weapon_ammo_spawn` in `weaponsToRemove` table

**Status:** NO FIX NEEDED

---

### DISPUTED: RandomFloat May Not Exist

**Claim:** `RandomFloat()` might not be a valid VScript function.

**Research Finding:** DISPUTED. `RandomFloat(min, max)` IS a standard L4D2 VScript function documented in Valve Developer Wiki. Used extensively in official mutation scripts and Left4Lib.

**Status:** NO FIX NEEDED

---

### VERIFIED: IsPlayerABot Is Valid

**Claim:** `IsPlayerABot()` might not be a valid function.

**Research Finding:** VERIFIED CORRECT. `IsPlayerABot(player)` is a global VScript function (not a method). Evidence from Left4Lib source code shows extensive use:
```squirrel
if (ent.IsValid() && !IsPlayerABot(ent) && ...)
```

**Status:** NO FIX NEEDED

---

## Research Sources

### Primary Sources
1. **Valve Developer Community Wiki (Archived)**
   - https://web.archive.org/web/20240608080829/https://developer.valvesoftware.com/wiki/List_of_L4D2_Script_Functions
   - L4D2 VScript function documentation

2. **Left4Lib by smilz0**
   - https://github.com/smilz0/Left4Lib
   - https://steamcommunity.com/sharedfiles/filedetails/?id=2634208272
   - Key files: `left4lib_utils.nut`, `left4lib_consts.nut`
   - Evidence for: IsPlayerABot, kickid command, director cvars, ZSpawn, NavMesh

3. **L4D2-Community-Update by Tsuey**
   - https://github.com/Tsuey/L4D2-Community-Update
   - Official community patches and VScript examples

### Key Findings from Research

#### Weapon/Ammo Control (from VDC Wiki)
```squirrel
// Strip weapons via NetProps
NetProps.GetPropEntityArray(player, "m_hMyWeapons", slot)

// Set clip ammo
weapon.SetClip1(amount)

// Set reserve ammo (index 2 = sniper/hunting rifle)
NetProps.SetPropIntArray(player, "m_iAmmo", 0, ammoIndex)
```

#### Director Control (from Left4Lib)
```squirrel
// These cvars do NOT require sv_cheats via VScript
Convars.SetValue("director_no_bosses", 1)
Convars.SetValue("director_no_mobs", 1)
Convars.SetValue("z_common_limit", 0)
```

#### Event Registration (from VDC Wiki)
```squirrel
// Required for OnGameEvent_* functions to fire
__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)
```

#### Melee Headshot Limitation
- `Hitgroup` field in `AllowTakeDamage` is NOT populated for melee attacks
- `DMG_HEADSHOT` flag (1073741824) is only set for gun hits, never melee
- This is a Source Engine limitation, not fixable via VScript

---

## Final Implementation Summary

### Files Modified
- `scripts/vscripts/survival_horror.nut` (988 lines)

### Key Functions

| Function | Purpose |
|----------|---------|
| `ApplyConvarSettings()` | Sets all director/gameplay cvars |
| `RegisterCallbacks()` | Registers all callbacks to roottable |
| `SetupPlayerLoadout()` | Strips weapons, gives rifle, schedules ammo setup |
| `FinalizePlayerAmmo()` | Sets clip=20, reserve=0 |
| `KickAllSurvivorBots()` | Removes AI survivors |
| `CullZombiesToTarget()` | Cluster-aware zombie culling |
| `CountInfected()` | Counts current common infected |
| `AllowTakeDamage()` | Headshots-only for guns, tiered random for melee |
| `GetDefaultItem()` | Returns hunting_rifle for slot 0, blocks others |
| `OnGameEvent_*` | Various event handlers |

### Gameplay Parameters

| Parameter | Value |
|-----------|-------|
| Starting weapon | Hunting rifle |
| Total ammo | 20 rounds (clip only) |
| Reserve ammo | 0 (blocked) |
| Max zombies | 80 |
| Cull delay | 2.5 seconds after round start |
| Cluster distances | 2m (very close), 4m (close), 16m (nearby) |
| Melee Tier 1 multiplier | 1.0 (25-100% final) |
| Melee Tier 2 multiplier | 0.5 (12.5-50% final) |
| Melee Tier 3 multiplier | 0.25 (6.25-25% final) |
| Survivor bots | Disabled and kicked |
| Friendly fire | Enabled |
| Special infected | All disabled |
| Panic events | Disabled |

---

## Testing Checklist

- [ ] Player spawns with hunting rifle only (no pistol)
- [ ] Rifle has 20 rounds in clip
- [ ] Rifle has 0 reserve ammo
- [ ] Walking over ammo pile does NOT increase ammo
- [ ] Melee damage varies (some kills, some don't)
- [ ] Gun body shots do 0 damage to infected
- [ ] Gun headshots kill infected
- [ ] Zombie count is ≤80 after ~3 seconds
- [ ] No new zombies spawn during gameplay
- [ ] AI survivor bots are kicked
- [ ] Events fire correctly (check console for Msg output)
