//==============================================================================
// SURVIVAL HORROR MUTATION
// A stealth survival horror experience for Left 4 Dead 2
//
// Features:
// - HUMANS ONLY - no AI survivor bots allowed
// - Reduced zombie population (max 80, culled by clusters at round start)
// - Headshots only to kill infected with GUNS
// - Melee weapons: tiered damage with random multiplier (25%-100%)
//     - Tier 1 (katana, machete, fireaxe, chainsaw): 25%-100% damage
//     - Tier 2 (baseball bat, crowbar, etc.): 12.5%-50% damage
//     - Tier 3 (frying pan, tonfa): 6.25%-25% damage
// - Hunting rifle with 20 bullets total (all in clip, no reserve, no pickups)
// - No special infected
// - Fragile survivors (2-3 hits to incap, next hit = death)
// - No healing items
// - No panic events
// - Friendly fire enabled
//
// Usage: script_execute survival_horror
//==============================================================================

Msg("Survival Horror Mutation Loading...\n")

//------------------------------------------------------------------------------
// CONSTANTS
//------------------------------------------------------------------------------
// Zombie control
ZOMBIE_TARGET_COUNT <- 80         // Max zombies on map
ZOMBIE_CULL_DELAY <- 2.5          // Seconds after round start to cull

// Cluster scoring distances (in Source units)
// Used to prioritize killing clustered zombies during culling
CLUSTER_DIST_VERY_CLOSE <- 66     // 2 meters - score +3
CLUSTER_DIST_CLOSE <- 131         // 4 meters - score +2
CLUSTER_DIST_NEARBY <- 525        // 16 meters - score +1

// Ammo settings
HUNTING_RIFLE_CLIP <- 20          // Total ammo (all in clip, no reserve)
HUNTING_RIFLE_AMMO_INDEX <- 2     // NetProp index for sniper/hunting rifle ammo

//------------------------------------------------------------------------------
// APPLY SETTINGS VIA CONVARS (works with script_execute)
//------------------------------------------------------------------------------
function ApplyConvarSettings()
{
    Msg("Survival Horror: Applying convar settings...\n")

    // NOTE: sv_cheats is NOT required for these cvars via VScript
    // VScript Convars.SetValue() has elevated privileges compared to console commands
    // Removing sv_cheats prevents players from using cheat commands

    // Set hunting rifle max reserve ammo to 0 (we use clip only, set via SetClip1)
    Convars.SetValue("ammo_huntingrifle_max", 0)

    // Disable special infected
    Convars.SetValue("z_smoker_limit", 0)
    Convars.SetValue("z_boomer_limit", 0)
    Convars.SetValue("z_hunter_limit", 0)
    Convars.SetValue("z_spitter_limit", 0)
    Convars.SetValue("z_jockey_limit", 0)
    Convars.SetValue("z_charger_limit", 0)

    // Disable bosses
    Convars.SetValue("z_tank_limit", 0)
    Convars.SetValue("z_witch_limit", 0)
    Convars.SetValue("director_no_bosses", 1)
    Convars.SetValue("director_no_specials", 1)

    // Disable mobs/hordes and limit common infected count
    Convars.SetValue("director_no_mobs", 1)
    Convars.SetValue("z_common_limit", ZOMBIE_TARGET_COUNT)  // Max 80 common infected

    // Friendly fire
    Convars.SetValue("mp_friendlyfire", 1)

    // Survivor settings
    Convars.SetValue("survivor_max_incapacitated_count", 1)
    Convars.SetValue("survivor_respawn_with_guns", 0)
    
    // Disable survivor bots - humans only
    Convars.SetValue("sb_all_bot_game", 0)
    Convars.SetValue("allow_all_bot_survivor_team", 0)

    Msg("Survival Horror: Convars applied!\n")
}

// Apply settings immediately on script load
ApplyConvarSettings()

//------------------------------------------------------------------------------
// REGISTER CALLBACKS - Ensure callbacks work with script_execute
//------------------------------------------------------------------------------
function RegisterCallbacks()
{
    // Put our callbacks in the root table so the director can find them
    if (!("AllowTakeDamage" in getroottable()))
    {
        getroottable().AllowTakeDamage <- AllowTakeDamage
        Msg("Survival Horror: AllowTakeDamage registered\n")
    }

    if (!("AllowWeaponSpawn" in getroottable()))
    {
        getroottable().AllowWeaponSpawn <- AllowWeaponSpawn
        Msg("Survival Horror: AllowWeaponSpawn registered\n")
    }

    if (!("GetDefaultItem" in getroottable()))
    {
        getroottable().GetDefaultItem <- GetDefaultItem
        Msg("Survival Horror: GetDefaultItem registered\n")
    }
    
    // Register ALL OnGameEvent_* functions to roottable
    // Without this, event handlers won't be found by the engine
    
    if (!("OnGameEvent_round_start" in getroottable()))
    {
        getroottable().OnGameEvent_round_start <- OnGameEvent_round_start
        Msg("Survival Horror: OnGameEvent_round_start registered\n")
    }
    
    if (!("OnGameEvent_player_spawn" in getroottable()))
    {
        getroottable().OnGameEvent_player_spawn <- OnGameEvent_player_spawn
        Msg("Survival Horror: OnGameEvent_player_spawn registered\n")
    }
    
    if (!("OnGameEvent_ammo_pickup" in getroottable()))
    {
        getroottable().OnGameEvent_ammo_pickup <- OnGameEvent_ammo_pickup
        Msg("Survival Horror: OnGameEvent_ammo_pickup registered\n")
    }
    
    if (!("OnGameEvent_infected_spawn" in getroottable()))
    {
        getroottable().OnGameEvent_infected_spawn <- OnGameEvent_infected_spawn
        Msg("Survival Horror: OnGameEvent_infected_spawn registered\n")
    }
    
    if (!("OnGameEvent_player_incapacitated" in getroottable()))
    {
        getroottable().OnGameEvent_player_incapacitated <- OnGameEvent_player_incapacitated
        Msg("Survival Horror: OnGameEvent_player_incapacitated registered\n")
    }
    
    if (!("OnGameEvent_round_start_post_nav" in getroottable()))
    {
        getroottable().OnGameEvent_round_start_post_nav <- OnGameEvent_round_start_post_nav
        Msg("Survival Horror: OnGameEvent_round_start_post_nav registered\n")
    }
    
    if (!("OnGameEvent_player_first_spawn" in getroottable()))
    {
        getroottable().OnGameEvent_player_first_spawn <- OnGameEvent_player_first_spawn
        Msg("Survival Horror: OnGameEvent_player_first_spawn registered\n")
    }
}

//------------------------------------------------------------------------------
// MUTATION OPTIONS - Core Director settings
//------------------------------------------------------------------------------
MutationOptions <-
{
    //==========================================================================
    // ZOMBIE POPULATION - Use default level population
    //==========================================================================
    // CommonLimit, WanderingZombieDensityModifier, etc. left at defaults
    // to preserve normal zombie counts per level
    
    // Disable mob spawns (hordes) - no panic events
    NoMobSpawns = true
    
    //==========================================================================
    // NO SPECIAL INFECTED - Pure zombie horror
    //==========================================================================
    MaxSpecials = 0
    cm_MaxSpecials = 0
    DominatorLimit = 0
    SmokerLimit = 0
    BoomerLimit = 0
    HunterLimit = 0
    SpitterLimit = 0
    JockeyLimit = 0
    ChargerLimit = 0
    TankLimit = 0
    WitchLimit = 0
    cm_TankLimit = 0
    cm_WitchLimit = 0
    ProhibitBosses = true
    cm_ProhibitBosses = true
    
    //==========================================================================
    // HEADSHOTS ONLY - Handled via AllowTakeDamage callback
    // Set to false so melee weapons bypass the engine-level headshot check
    //==========================================================================
    cm_HeadshotOnly = false
    
    //==========================================================================
    // PLAYER FRAGILITY
    // Default common infected damage is ~1-2 per hit
    // We increase via AllowTakeDamage callback
    //==========================================================================
    SurvivorMaxIncapacitatedCount = 1         // Can be incapped once, second = death
    TempHealthDecayRate = 0.5                 // Temp health decays faster
    
    //==========================================================================
    // ZOMBIE DETECTION - Stealth mechanics
    // Zombies can be avoided with careful movement
    //==========================================================================
    FarAcquireRange = 600.0                   // Can spot survivors up to 600 units
    NearAcquireRange = 150.0                  // Close range detection
    FarAcquireTime = 4.0                      // Takes 4 seconds to notice at max range
    NearAcquireTime = 0.0                     // Instant detection if close
    ZombieSpawnRange = 1200.0                 // Spawn distance from survivors
    ZombieDiscardRange = 2000                 // Cleanup range
    
    // Wanderer behavior
    IntensityRelaxAllowWanderersThreshold = 0.05
    AlwaysAllowWanderers = false
    
    //==========================================================================
    // PACING - Keep it tense but not overwhelming
    //==========================================================================
    LockTempo = false
    RelaxMinInterval = 60
    RelaxMaxInterval = 90
    RelaxMaxFlowTravel = 600
    SustainPeakMinTime = 1
    SustainPeakMaxTime = 2
    IntensityRelaxThreshold = 0.5
    
    //==========================================================================
    // DISABLE PANIC EVENTS AND CRESCENDOS
    //==========================================================================
    AllowCrescendoEvents = false
    
    //==========================================================================
    // MISCELLANEOUS
    //==========================================================================
    cm_AllowPillConversion = false            // No item conversions
    cm_AllowSurvivorRescue = false            // No rescue closets - death matters
    cm_NoSurvivorBots = true                  // NO BOTS - humans only
    cm_ShouldHurry = false                    // Bots don't rush

    // Water doesn't slow (for escaping)
    WaterSlowsMovement = false

    //==========================================================================
    // BLOCK ITEM SPAWNS - No healing, no guns, no throwables
    //==========================================================================
    FirstAidItem = 0                          // No medkits
    PillsItem = 0                             // No pills
    MolotovItem = 0                           // No molotovs
    PipeBombItem = 0                          // No pipe bombs
    VomitJarItem = 0                          // No bile bombs
    AdrenalItem = 0                           // No adrenaline
    DefibrillatorItem = 0                     // No defibs
    UpgradePackItem = 0                       // No upgrade packs
    PrimaryWeaponItem = 0                     // No primary weapons
    SecondaryWeaponItem = 0                   // No secondary weapons
    MeleeWeaponItem = 100                     // Melee weapons spawn normally
}

//------------------------------------------------------------------------------
// MUTATION STATE - Tracks runtime state
//------------------------------------------------------------------------------
MutationState <-
{
    AmmoInitialized = false
    StartingAmmo = 5  // Reserve ammo (15 in clip + 5 reserve = 20 total)
}

//------------------------------------------------------------------------------
// MELEE WEAPON TIERS - Different weapons have different effectiveness
//------------------------------------------------------------------------------
// Tier 1 - Lethal bladed weapons (1-hit kill)
tier1Melee <- {
    katana = true
    machete = true
    fireaxe = true
    chainsaw = true
}

// Tier 2 - Heavy blunt weapons (2-hit kill)
tier2Melee <- {
    baseball_bat = true
    cricket_bat = true
    crowbar = true
    golfclub = true
    electric_guitar = true
    shovel = true
    pitchfork = true
    knife = true
}

// Tier 3 - Light/improvised weapons (3-hit kill)
tier3Melee <- {
    frying_pan = true
    tonfa = true
}

//------------------------------------------------------------------------------
// WEAPONS TO REMOVE - Items that should not spawn
//------------------------------------------------------------------------------
weaponsToRemove <-
{
    // Health items
    weapon_first_aid_kit = 0
    weapon_first_aid_kit_spawn = 0
    weapon_pain_pills = 0
    weapon_pain_pills_spawn = 0
    weapon_adrenaline = 0
    weapon_adrenaline_spawn = 0
    weapon_defibrillator = 0
    weapon_defibrillator_spawn = 0

    // Throwables
    weapon_molotov = 0
    weapon_molotov_spawn = 0
    weapon_pipe_bomb = 0
    weapon_pipe_bomb_spawn = 0
    weapon_vomitjar = 0
    weapon_vomitjar_spawn = 0

    // Guns - all types (we only want hunting rifle from spawn)
    weapon_pistol = 0
    weapon_pistol_spawn = 0
    weapon_pistol_magnum = 0
    weapon_pistol_magnum_spawn = 0
    weapon_smg = 0
    weapon_smg_spawn = 0
    weapon_smg_silenced = 0
    weapon_smg_silenced_spawn = 0
    weapon_smg_mp5 = 0
    weapon_smg_mp5_spawn = 0
    weapon_pumpshotgun = 0
    weapon_pumpshotgun_spawn = 0
    weapon_shotgun_chrome = 0
    weapon_shotgun_chrome_spawn = 0
    weapon_autoshotgun = 0
    weapon_autoshotgun_spawn = 0
    weapon_shotgun_spas = 0
    weapon_shotgun_spas_spawn = 0
    weapon_rifle = 0
    weapon_rifle_spawn = 0
    weapon_rifle_ak47 = 0
    weapon_rifle_ak47_spawn = 0
    weapon_rifle_desert = 0
    weapon_rifle_desert_spawn = 0
    weapon_rifle_sg552 = 0
    weapon_rifle_sg552_spawn = 0
    weapon_hunting_rifle = 0  // Block spawned hunting rifles (we give one at start)
    weapon_hunting_rifle_spawn = 0
    weapon_sniper_military = 0
    weapon_sniper_military_spawn = 0
    weapon_sniper_scout = 0
    weapon_sniper_scout_spawn = 0
    weapon_sniper_awp = 0
    weapon_sniper_awp_spawn = 0
    weapon_grenade_launcher = 0
    weapon_grenade_launcher_spawn = 0
    weapon_rifle_m60 = 0
    weapon_rifle_m60_spawn = 0

    // Ammo and upgrades
    weapon_ammo_spawn = 0
    weapon_upgradepack_incendiary = 0
    weapon_upgradepack_incendiary_spawn = 0
    weapon_upgradepack_explosive = 0
    weapon_upgradepack_explosive_spawn = 0
    upgrade_ammo_incendiary = 0
    upgrade_ammo_explosive = 0
}

//------------------------------------------------------------------------------
// RemoveUnwantedItems - AGGRESSIVE removal of all items
//------------------------------------------------------------------------------
function RemoveUnwantedItems()
{
    Msg("Survival Horror: Starting aggressive item removal...\n")
    local removeCount = 0
    
    // Remove all items in weaponsToRemove table
    foreach (weaponClass, _ in weaponsToRemove)
    {
        // Kill spawn entities
        EntFire(weaponClass, "Kill")
        
        // Find and kill actual spawned items
        local ent = null
        while ((ent = Entities.FindByClassname(ent, weaponClass)) != null)
        {
            ent.Kill()
            removeCount++
        }
    }
    
    // Also specifically target common spawn entity names
    EntFire("weapon_spawn", "Kill")
    EntFire("weapon_item_spawn", "Kill")
    
    Msg("Survival Horror: Removed " + removeCount + " items from map\n")
}

//------------------------------------------------------------------------------
// SetupPlayerLoadout - Complete weapon setup for survival horror
// Strips all weapons, gives hunting rifle with 20 rounds (no reserve)
//------------------------------------------------------------------------------
function SetupPlayerLoadout(player)
{
    if (player == null) return
    if (!player.IsValid()) return
    
    try {
        Msg("Survival Horror: Setting up loadout for player\n")
        
        // Step 1: Strip ALL weapons by iterating m_hMyWeapons array (slots 0-5)
        for (local i = 0; i < 6; i++)
        {
            local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
            if (weapon != null && weapon.IsValid())
            {
                local classname = weapon.GetClassname()
                weapon.Kill()
                Msg("Survival Horror: Stripped " + classname + " from slot " + i + "\n")
            }
        }
        
        // Step 2: Give hunting rifle
        player.GiveItem("hunting_rifle")
        Msg("Survival Horror: Gave hunting rifle\n")
        
        // Step 3: Set clip to 20 and reserve to 0 (after short delay for weapon to equip)
        DoEntFire("!self", "RunScriptCode", "FinalizePlayerAmmo(GetPlayerFromUserID(" + player.GetPlayerUserId() + "))", 0.1, null, null)
    }
    catch (e)
    {
        Msg("Survival Horror: Error in SetupPlayerLoadout: " + e + "\n")
    }
}

//------------------------------------------------------------------------------
// FinalizePlayerAmmo - Set clip to 20 and reserve to 0
// Called after weapon is equipped
//------------------------------------------------------------------------------
function FinalizePlayerAmmo(player)
{
    if (player == null) return
    if (!player.IsValid()) return
    
    try {
        // Find hunting rifle by iterating weapon slots (more robust than GetActiveWeapon)
        // This works even if player has switched to another weapon
        local foundRifle = false
        for (local i = 0; i < 6; i++)
        {
            local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
            if (weapon != null && weapon.IsValid() && weapon.GetClassname() == "weapon_hunting_rifle")
            {
                // Set clip to 20 rounds
                weapon.SetClip1(HUNTING_RIFLE_CLIP)
                Msg("Survival Horror: Set clip to " + HUNTING_RIFLE_CLIP + " rounds (slot " + i + ")\n")
                foundRifle = true
                break
            }
        }
        
        if (!foundRifle)
        {
            Msg("Survival Horror: Warning - hunting rifle not found in inventory\n")
        }
        
        // Set ALL reserve ammo types to 0 to be thorough
        for (local i = 0; i < 32; i++)
        {
            NetProps.SetPropIntArray(player, "m_iAmmo", 0, i)
        }
        Msg("Survival Horror: Cleared all reserve ammo\n")
    }
    catch (e)
    {
        Msg("Survival Horror: Error in FinalizePlayerAmmo: " + e + "\n")
    }
}

//------------------------------------------------------------------------------
// KickAllSurvivorBots - Remove all AI survivor bots from the game
//------------------------------------------------------------------------------
function KickAllSurvivorBots()
{
    local kickedCount = 0
    local ent = null
    
    while ((ent = Entities.FindByClassname(ent, "player")) != null)
    {
        if (ent.IsValid() && ent.IsSurvivor())
        {
            try {
                if (IsPlayerABot(ent))
                {
                    // Kick the bot using userid (more reliable than player name)
                    local userid = ent.GetPlayerUserId()
                    SendToServerConsole("kickid " + userid)
                    kickedCount++
                    Msg("Survival Horror: Kicked bot survivor (userid " + userid + ")\n")
                }
            }
            catch (e) {}
        }
    }
    
    if (kickedCount > 0)
    {
        Msg("Survival Horror: Kicked " + kickedCount + " survivor bots (humans only!)\n")
    }
    
    return kickedCount
}

//------------------------------------------------------------------------------
// CountInfected - Count current common infected on the map
//------------------------------------------------------------------------------
function CountInfected()
{
    local count = 0
    local ent = null
    while ((ent = Entities.FindByClassname(ent, "infected")) != null)
    {
        if (ent.IsValid())
            count++
    }
    return count
}

//------------------------------------------------------------------------------
// CullZombiesToTarget - Reduce zombie count using cluster-aware culling
// Preferentially removes zombies that are close to other zombies
//------------------------------------------------------------------------------
function CullZombiesToTarget(targetCount)
{
    Msg("Survival Horror: Starting cluster-aware zombie culling...\n")
    
    // Step 1: Collect all infected entities
    local zombies = []
    local ent = null
    while ((ent = Entities.FindByClassname(ent, "infected")) != null)
    {
        if (ent.IsValid())
            zombies.append(ent)
    }
    
    local currentCount = zombies.len()
    Msg("Survival Horror: Found " + currentCount + " zombies on map\n")
    
    // If already at or below target, nothing to do
    if (currentCount <= targetCount)
    {
        Msg("Survival Horror: Count (" + currentCount + ") <= target (" + targetCount + "), no culling needed\n")
        return
    }
    
    local toDelete = currentCount - targetCount
    Msg("Survival Horror: Need to cull " + toDelete + " zombies\n")
    
    // Step 2: Calculate cluster score for each zombie
    // Higher score = more clustered = higher priority for deletion
    local scored = []
    foreach (zombie in zombies)
    {
        local pos = zombie.GetOrigin()
        local clusterScore = 0
        
        // Count nearby zombies and score based on distance
        foreach (other in zombies)
        {
            if (other == zombie) continue
            
            local dist = (other.GetOrigin() - pos).Length()
            
            if (dist < CLUSTER_DIST_VERY_CLOSE)
                clusterScore += 3  // Very close (2m) - high score
            else if (dist < CLUSTER_DIST_CLOSE)
                clusterScore += 2  // Close (4m) - medium score
            else if (dist < CLUSTER_DIST_NEARBY)
                clusterScore += 1  // Nearby (16m) - low score
        }
        
        scored.append({ zombie = zombie, score = clusterScore })
    }
    
    // Step 3: Sort by cluster score (highest first)
    // Squirrel sort is in-place, compare function returns negative/zero/positive
    scored.sort(function(a, b) {
        if (b.score > a.score) return 1
        if (b.score < a.score) return -1
        return 0
    })
    
    // Step 4: Delete the most clustered zombies
    local deleted = 0
    for (local i = 0; i < toDelete && i < scored.len(); i++)
    {
        if (scored[i].zombie.IsValid())
        {
            scored[i].zombie.Kill()
            deleted++
        }
    }
    
    Msg("Survival Horror: Culled " + deleted + " zombies, " + (currentCount - deleted) + " remaining\n")
}

//------------------------------------------------------------------------------
// GetDefaultItem - Starting loadout
// Players start with only a Hunting Rifle (20 rounds total)
// Return "" to explicitly block a slot, not 0 (which may be converted to string "0")
//------------------------------------------------------------------------------
function GetDefaultItem(index)
{
    if (index == 0) return "hunting_rifle"
    return ""  // Block all other slots (pistol, etc.)
}

//------------------------------------------------------------------------------
// AllowWeaponSpawn - Block all weapon/item spawns except melee
//------------------------------------------------------------------------------
function AllowWeaponSpawn(classname)
{
    // Check if this weapon should be removed
    if (classname in weaponsToRemove)
    {
        Msg("Survival Horror: Blocked spawn of " + classname + "\n")
        return false
    }

    // Allow melee weapons
    if (classname == "weapon_melee") return true
    if (classname == "weapon_melee_spawn") return true
    if (classname.find("melee") != null) return true

    // Block everything else by default
    Msg("Survival Horror: Blocked unknown spawn: " + classname + "\n")
    return false
}

//------------------------------------------------------------------------------
// ConvertWeaponSpawn - Convert any gun spawns to melee
//------------------------------------------------------------------------------
function ConvertWeaponSpawn(classname)
{
    // Convert gun spawns to nothing (they'll be blocked anyway)
    // But if something slips through, make it melee
    if (classname.find("pistol") != null) return ""
    if (classname.find("rifle") != null) return "weapon_melee"
    if (classname.find("shotgun") != null) return "weapon_melee"
    if (classname.find("smg") != null) return "weapon_melee"
    if (classname.find("sniper") != null) return "weapon_melee"
    if (classname.find("hunting") != null) return "weapon_melee"
    if (classname.find("grenade") != null) return ""
    if (classname.find("launcher") != null) return ""
    
    return classname
}

//------------------------------------------------------------------------------
// GetMeleeWeaponName - Try to get the melee weapon script name from attacker
//------------------------------------------------------------------------------
function GetMeleeWeaponName(attacker)
{
    if (attacker == null) return ""

    try {
        local weapon = attacker.GetActiveWeapon()
        if (weapon != null)
        {
            // Try to get the script name (e.g., "katana", "baseball_bat")
            if (weapon.GetClassname() == "weapon_melee")
            {
                // GetScriptScope or similar might have the melee type
                // Fall back to checking model name patterns
                local modelName = weapon.GetModelName()
                if (modelName != null)
                {
                    // Extract weapon name from model path
                    // e.g., "models/weapons/melee/v_katana.mdl" -> "katana"
                    modelName = modelName.tolower()
                    if (modelName.find("katana") != null) return "katana"
                    if (modelName.find("machete") != null) return "machete"
                    if (modelName.find("fireaxe") != null) return "fireaxe"
                    if (modelName.find("chainsaw") != null) return "chainsaw"
                    if (modelName.find("baseball") != null) return "baseball_bat"
                    if (modelName.find("cricket") != null) return "cricket_bat"
                    if (modelName.find("crowbar") != null) return "crowbar"
                    if (modelName.find("golf") != null) return "golfclub"
                    if (modelName.find("guitar") != null) return "electric_guitar"
                    if (modelName.find("shovel") != null) return "shovel"
                    if (modelName.find("pitchfork") != null) return "pitchfork"
                    if (modelName.find("knife") != null) return "knife"
                    if (modelName.find("frying") != null) return "frying_pan"
                    if (modelName.find("pan") != null) return "frying_pan"
                    if (modelName.find("tonfa") != null) return "tonfa"
                }
            }
        }
    } catch(e) {
        // Silently fail if we can't get weapon info
    }

    return ""
}

//------------------------------------------------------------------------------
// GetMeleeTierMultiplier - Get base damage multiplier based on weapon tier
// This is combined with a random multiplier (0.25-1.0) for final damage
//------------------------------------------------------------------------------
function GetMeleeTierMultiplier(weaponName)
{
    // Tier 1 - Full base damage (bladed weapons)
    if (weaponName in tier1Melee) return 1.0

    // Tier 2 - Half base damage (blunt weapons)
    if (weaponName in tier2Melee) return 0.5

    // Tier 3 - Quarter base damage (improvised weapons)
    if (weaponName in tier3Melee) return 0.25

    // Unknown weapon - default to tier 2
    return 0.5
}



//------------------------------------------------------------------------------
// AllowTakeDamage - Headshots only for guns, tiered random damage for melee
//------------------------------------------------------------------------------
function AllowTakeDamage(dmgTable)
{
    // Validate the damage table
    if (!("Victim" in dmgTable)) return true
    if (dmgTable.Victim == null) return true

    local victim = dmgTable.Victim
    local attacker = ("Attacker" in dmgTable) ? dmgTable.Attacker : null
    local victimClass = victim.GetClassname()

    //--------------------------------------------------------------------------
    // DAMAGE TO INFECTED - Headshots only for guns, tiered random for melee
    //--------------------------------------------------------------------------
    if (victimClass == "infected")
    {
        local hitgroup = ("Hitgroup" in dmgTable) ? dmgTable.Hitgroup : -1
        local dmgType = ("DamageType" in dmgTable) ? dmgTable.DamageType : 0
        local isHeadshot = (hitgroup == 1)  // Hitgroup 1 = head

        // Check if attacker is using a melee weapon (more reliable than damage types)
        local isMelee = false
        local weaponName = ""
        if (attacker != null)
        {
            try {
                local weapon = attacker.GetActiveWeapon()
                if (weapon != null && weapon.GetClassname() == "weapon_melee")
                {
                    isMelee = true
                    weaponName = GetMeleeWeaponName(attacker)
                }
            } catch(e) {}
        }

        // Fallback: also check damage types DMG_SLASH (4), DMG_CLUB (128)
        if (!isMelee && ((dmgType & 4) || (dmgType & 128)))
        {
            isMelee = true
            weaponName = GetMeleeWeaponName(attacker)
        }

        if (isMelee)
        {
            //==================================================================
            // MELEE DAMAGE: Tier multiplier * Random multiplier
            //==================================================================
            // Tier 1 (bladed): 1.0 base -> 25%-100% final damage
            // Tier 2 (blunt):  0.5 base -> 12.5%-50% final damage
            // Tier 3 (improv): 0.25 base -> 6.25%-25% final damage
            //
            // This creates variable damage that makes melee unreliable
            // but still useful. Sometimes you get lucky, sometimes not.
            //==================================================================
            
            local tierMultiplier = GetMeleeTierMultiplier(weaponName)
            local randomMultiplier = 0.25 + (RandomFloat(0.0, 1.0) * 0.75)  // 0.25 to 1.0
            
            dmgTable.DamageDone = dmgTable.DamageDone * tierMultiplier * randomMultiplier
            
            return true
        }
        else if (!isHeadshot)
        {
            // Gun body shot - block damage (headshots only rule)
            dmgTable.DamageDone = 0
            return true
        }
        // Gun headshot - allow full damage
    }

    //--------------------------------------------------------------------------
    // SURVIVOR FRAGILITY - Take more damage from infected
    //--------------------------------------------------------------------------
    if (victimClass == "player" || victimClass == "survivor_bot")
    {
        if (attacker != null && attacker.GetClassname() == "infected")
        {
            // 5x damage from common infected
            // Normal hit = 1-2 damage, now = 5-10 damage
            // Roughly 10-20 hits to incap
            dmgTable.DamageDone = dmgTable.DamageDone * 5.0
        }
    }

    return true
}

//------------------------------------------------------------------------------
// ShouldAvoidItem - Make bots prefer melee over guns
//------------------------------------------------------------------------------
function ShouldAvoidItem(classname)
{
    // Bots should avoid picking up extra hunting rifles
    if (classname.find("hunting_rifle") != null) return true
    
    // Bots should avoid all other guns
    if (classname.find("pistol") != null) return true
    if (classname.find("rifle") != null) return true
    if (classname.find("shotgun") != null) return true
    if (classname.find("smg") != null) return true
    if (classname.find("sniper") != null) return true
    
    // Don't avoid melee
    if (classname.find("melee") != null) return false
    
    return false
}

//------------------------------------------------------------------------------
// OnGameEvent_round_start - Called when round starts
//------------------------------------------------------------------------------
function OnGameEvent_round_start(params)
{
    Msg("Survival Horror: Round starting...\n")

    // Remove unwanted items aggressively
    RemoveUnwantedItems()

    // Set friendly fire on
    Convars.SetValue("mp_friendlyfire", 1)
    
    // Set hunting rifle max ammo (reserve) - we set clip directly via SetClip1
    Convars.SetValue("ammo_huntingrifle_max", 0)
    Convars.SetValue("survivor_respawn_with_guns", 0)
    
    // Disable director panic spawns and limit zombie count
    Convars.SetValue("director_no_mobs", 1)
    Convars.SetValue("z_common_limit", ZOMBIE_TARGET_COUNT)
    
    MutationState.AmmoInitialized = false
    
    // Kick all survivor bots (humans only mode)
    DoEntFire("!self", "RunScriptCode", "KickAllSurvivorBots()", 1.0, null, null)
    
    // Cull zombies to target count after delay (let map finish spawning)
    DoEntFire("!self", "RunScriptCode", "CullZombiesToTarget(" + ZOMBIE_TARGET_COUNT + ")", ZOMBIE_CULL_DELAY, null, null)
}

//------------------------------------------------------------------------------
// OnGameEvent_player_spawn - Called when a player spawns
//------------------------------------------------------------------------------
function OnGameEvent_player_spawn(params)
{
    // Get the player entity
    local player = GetPlayerFromUserID(params.userid)
    if (player == null) return
    
    // Skip bots - they shouldn't be here anyway, but just in case
    try {
        if (IsPlayerABot(player)) return
    } catch (e) {}
    
    // Setup complete loadout after 1 second delay (strip all weapons, give rifle, set ammo)
    DoEntFire("!self", "RunScriptCode", "SetupPlayerLoadout(GetPlayerFromUserID(" + params.userid + "))", 1.0, null, null)
}

//------------------------------------------------------------------------------
// OnGameEvent_ammo_pickup - Block ammo pickups by resetting reserve to 0
//------------------------------------------------------------------------------
function OnGameEvent_ammo_pickup(params)
{
    local player = GetPlayerFromUserID(params.userid)
    if (player == null) return
    
    // Immediately reset all reserve ammo to 0
    try {
        for (local i = 0; i < 32; i++)
        {
            NetProps.SetPropIntArray(player, "m_iAmmo", 0, i)
        }
        Msg("Survival Horror: Blocked ammo pickup, reset reserve to 0\n")
    }
    catch (e) {}
}

//------------------------------------------------------------------------------
// OnGameEvent_infected_spawn - Auto-cull if zombie count exceeds target
//------------------------------------------------------------------------------
function OnGameEvent_infected_spawn(params)
{
    // Check current count
    local count = CountInfected()
    if (count > ZOMBIE_TARGET_COUNT)
    {
        // Too many zombies - cull back down
        Msg("Survival Horror: Zombie count (" + count + ") exceeds target, culling...\n")
        CullZombiesToTarget(ZOMBIE_TARGET_COUNT)
    }
}

//------------------------------------------------------------------------------
// OnGameEvent_player_incapacitated - Player went down
//------------------------------------------------------------------------------
function OnGameEvent_player_incapacitated(params)
{
    Msg("Survival Horror: A survivor has fallen!\n")
}

//------------------------------------------------------------------------------
// REGISTER EVENT CALLBACKS
//------------------------------------------------------------------------------
function OnGameEvent_round_start_post_nav(params)
{
    // Additional setup after navigation is loaded
    Msg("Survival Horror: Map loaded, preparing horror...\n")

    // Remove unwanted items again (some maps spawn items late)
    RemoveUnwantedItems()
    
    // Schedule periodic removal to catch any late spawns
    DoEntFire("!self", "RunScriptCode", "RemoveUnwantedItems()", 5.0, null, null)
    DoEntFire("!self", "RunScriptCode", "RemoveUnwantedItems()", 10.0, null, null)
}

//------------------------------------------------------------------------------
// Print instructions to players
//------------------------------------------------------------------------------
function OnGameEvent_player_first_spawn(params)
{
    // Show instructions
    ClientPrint(null, 3, "=== SURVIVAL HORROR ===")
    ClientPrint(null, 3, "Headshots only. 20 bullets. No pickups.")
    ClientPrint(null, 3, "Move carefully. Hide or die.")
}

//------------------------------------------------------------------------------
// FINAL INITIALIZATION
//------------------------------------------------------------------------------
// Register all callbacks to root table
RegisterCallbacks()

// Also register MutationOptions if not already there
if (!("MutationOptions" in getroottable()))
{
    getroottable().MutationOptions <- MutationOptions
    Msg("Survival Horror: MutationOptions registered\n")
}

// CRITICAL: Collect game event callbacks so the engine knows about OnGameEvent_* functions
// Without this call, event handlers will NOT fire!
__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)
Msg("Survival Horror: Game event callbacks collected\n")

// Apply convars again to make sure they stick
ApplyConvarSettings()

Msg("Survival Horror Mutation Script Initialized!\n")
Msg("=== SURVIVAL HORROR ACTIVE ===\n")
Msg("HUMANS ONLY - AI bots will be kicked.\n")
Msg("Headshots only for GUNS. Melee has random damage (25%-100% per tier).\n")
Msg("Hunting rifle with 20 rounds total. No ammo pickups.\n")
Msg("Max 80 zombies, culled by clusters.\n")