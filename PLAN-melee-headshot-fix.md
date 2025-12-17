# PLAN: Fix Melee Weapons Requiring Headshots

## Current Status

### Problem
Melee weapons are still requiring headshots to kill infected. The fire axe works (1-hit body kill), but the crowbar and other weapons still require headshots.

### What We've Tried
1. **Set `cm_HeadshotOnly = false`** (line 123) - Disabled the engine-level headshot enforcement so the `AllowTakeDamage` callback can handle damage logic manually.

2. **Improved melee detection** (lines 454-474) - Added direct weapon class check (`weapon.GetClassname() == "weapon_melee"`) in addition to damage type checks (`DMG_SLASH`, `DMG_CLUB`).

### Current Implementation

**AllowTakeDamage Logic (lines 435-507):**
```
1. Check if victim is "infected"
2. Detect if attack is melee by:
   - Checking attacker's active weapon classname == "weapon_melee"
   - Fallback: Check damage types (DMG_SLASH=4, DMG_CLUB=128)
3. If melee: Apply tier multiplier, allow damage
4. If gun body shot: Block damage (set to 0)
5. If gun headshot: Allow full damage
```

**Melee Tiers:**
- Tier 1 (1-hit kill): katana, machete, fireaxe, chainsaw
- Tier 2 (2-hit kill): baseball_bat, cricket_bat, crowbar, golfclub, electric_guitar, shovel, pitchfork, knife
- Tier 3 (3-hit kill): frying_pan, tonfa

---

## Possible Root Causes

### 1. AllowTakeDamage Callback Not Being Called
The callback might not be properly registered or invoked when using `script_execute`. The `RegisterCallbacks()` function adds it to the root table, but this may not be how the Director finds it.

**Evidence:** Fire axe works but crowbar doesn't - suggests callback IS being called but detection is inconsistent.

### 2. Callback Registration Method
Current registration (lines 64-84):
```squirrel
getroottable().AllowTakeDamage <- AllowTakeDamage
```
This may work for mutations but not for `script_execute` scenarios. The Director might look for callbacks in a different scope.

### 3. Melee Detection Failing for Some Weapons
The weapon classname check might fail silently (inside try/catch), and the damage type fallback might not cover all melee damage types.

### 4. Another Engine Setting Blocking Damage
There may be another convar or MutationOption that enforces headshot-only behavior that we haven't disabled.

---

## Next Steps to Investigate

### Step 1: Add Debug Logging
Add `Msg()` calls to verify the callback is being invoked and what values it sees:
```squirrel
function AllowTakeDamage(dmgTable)
{
    Msg("AllowTakeDamage called!\n")
    // ... log victim class, attacker, damage type, hitgroup, isMelee result
}
```

### Step 2: Check Callback Registration
Try alternative registration methods:
```squirrel
// Method A: DirectorScript
DirectorScript.AllowTakeDamage <- AllowTakeDamage

// Method B: SessionOptions
if ("SessionOptions" in getroottable()) {
    SessionOptions.AllowTakeDamage <- AllowTakeDamage
}
```

### Step 3: Test Without Tiered Damage
Simplify to always allow melee damage (remove multiplier logic) to isolate whether it's a detection or damage calculation issue.

### Step 4: Check for Conflicting Convars
Search for any convars that might enforce headshots:
- `z_non_head_damage_factor_expert`
- `z_non_head_damage_factor_hard`
- Other `z_` prefixed variables

### Step 5: Use Entity Input for Damage
If callbacks aren't reliable, consider using `TakeDamage` entity input directly or hooking `player_hurt` / `infected_hurt` game events.

---

## Files

- **Main Script:** `/Users/anthony/projects/survival_horror/scripts/vscripts/survival_horror.nut`
- **Mode Config:** `/Users/anthony/projects/survival_horror/modes/survival_horror.txt`

---

## Questions to Answer

1. Is `AllowTakeDamage` being called at all? (Add debug logging)
2. What damage type does the crowbar actually use?
3. Is the weapon detection returning the correct classname?
4. Are there difficulty-specific convars overriding our settings?
