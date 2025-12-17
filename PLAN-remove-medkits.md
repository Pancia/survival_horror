# Plan: Fix First Aid Kit Removal on Initial Table

## Problem
First aid kits still appear on the safe room table despite:
- `RemoveFirstAidKits()` function added
- Called from `OnGameEvent_round_start` and `OnGameEvent_round_start_post_nav`

## Possible Causes

1. **Timing**: Entities spawn after both events fire
2. **Wrong classname**: Safe room items might use `weapon_first_aid_kit_spawn` or another variant
3. **Callback not registered**: The `OnGameEvent_*` functions may not be hooked up properly for mutations
4. **Kill() not working**: May need a different removal method

## Proposed Fix

1. Add debug messages to confirm the function runs
2. Target both `weapon_first_aid_kit` AND `weapon_first_aid_kit_spawn`
3. Call from `OnGameEvent_player_first_spawn` as additional fallback (fires later)
4. If still failing, add delayed removal via `DirectorOptions.OnGameplayStart`

## File to Modify
`scripts/vscripts/survival_horror.nut`

## Changes

### 1. Update RemoveFirstAidKits() to target both classnames and log output

```squirrel
function RemoveFirstAidKits()
{
    Msg("Survival Horror: RemoveFirstAidKits running...\n")

    local classes = ["weapon_first_aid_kit", "weapon_first_aid_kit_spawn"]
    foreach (classname in classes)
    {
        local ent = null
        while ((ent = Entities.FindByClassname(ent, classname)) != null)
        {
            Msg("Survival Horror: Killing " + classname + "\n")
            ent.Kill()
        }
    }
}
```

### 2. Add call in OnGameEvent_player_first_spawn

```squirrel
function OnGameEvent_player_first_spawn(params)
{
    RemoveFirstAidKits()

    // Show instructions
    ClientPrint(null, 3, "=== SURVIVAL HORROR ===")
    ...
}
```
