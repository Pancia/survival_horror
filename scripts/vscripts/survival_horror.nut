//==============================================================================
// SURVIVAL HORROR MUTATION - LIMITED MAGNUM VERSION
// A stealth survival horror experience for Left 4 Dead 2
//
// REQUIRES: survival_horror_weapons_limited.vpk addon
// The weapon script addon changes the Magnum's ammo type from infinite
// AMMO_TYPE_PISTOL_MAGNUM to finite AMMO_TYPE_HUNTINGRIFLE
//
// Features:
// - HUMANS ONLY - no AI survivor bots allowed
// - Reduced zombie population (max 80, culled by clusters at round start)
// - Headshots only to kill infected with GUNS
// - Melee weapons: tiered damage with random multiplier (25%-100%)
// - MAGNUM with 12 bullets total (6 in clip, 6 reserve) - NO INFINITE AMMO
// - Standard pistol does 0 damage (forced by weapon script)
// - No special infected
// - Fragile survivors (2-3 hits to incap, next hit = death)
// - No healing items
// - No panic events
// - Friendly fire enabled
//
// Usage: script_execute survival_horror
//==============================================================================

Msg("Survival Horror Mutation (Limited Magnum) Loading...\n")

//------------------------------------------------------------------------------
// CONSTANTS
//------------------------------------------------------------------------------
// Zombie control
ZOMBIE_TARGET_COUNT <- 80         // Max zombies on map
ZOMBIE_CULL_DELAY <- 2.5          // Seconds after round start to cull

// Cluster scoring distances (in Source units)
CLUSTER_DIST_VERY_CLOSE <- 66     // 2 meters - score +3
CLUSTER_DIST_CLOSE <- 131         // 4 meters - score +2
CLUSTER_DIST_NEARBY <- 525        // 16 meters - score +1

// Ammo settings for Magnum (using AMMO_TYPE_HUNTINGRIFLE via weapon script)
MAGNUM_CLIP <- 6                  // Rounds in cylinder
MAGNUM_RESERVE <- 6               // Extra rounds (total 12)

//------------------------------------------------------------------------------
// APPLY SETTINGS VIA CONVARS
//------------------------------------------------------------------------------
function ApplyConvarSettings()
{
    Msg("Survival Horror: Applying convar settings...\n")

    //==========================================================================
    // CRITICAL: Set hunting rifle ammo max to 6
    // The Magnum now uses AMMO_TYPE_HUNTINGRIFLE (via weapon script addon)
    // so this controls the Magnum's reserve ammo!
    //==========================================================================
    Convars.SetValue("ammo_huntingrifle_max", MAGNUM_RESERVE)

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
    Convars.SetValue("z_common_limit", ZOMBIE_TARGET_COUNT)

    // Friendly fire
    Convars.SetValue("mp_friendlyfire", 1)

    // Survivor settings
    Convars.SetValue("survivor_max_incapacitated_count", 1)
    Convars.SetValue("survivor_respawn_with_guns", 0)
    
    // Disable survivor bots - humans only
    Convars.SetValue("sb_all_bot_game", 0)
    Convars.SetValue("allow_all_bot_survivor_team", 0)

    Msg("Survival Horror: Convars applied! Magnum reserve ammo = " + MAGNUM_RESERVE + "\n")
}

// Apply settings immediately on script load
ApplyConvarSettings()

//------------------------------------------------------------------------------
// REGISTER CALLBACKS
//------------------------------------------------------------------------------
function RegisterCallbacks()
{
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
// MUTATION OPTIONS
//------------------------------------------------------------------------------
MutationOptions <-
{
    // Disable mob spawns
    NoMobSpawns = true
    
    // NO SPECIAL INFECTED
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
    
    // Headshots handled via AllowTakeDamage
    cm_HeadshotOnly = false
    
    // PLAYER FRAGILITY
    SurvivorMaxIncapacitatedCount = 1
    TempHealthDecayRate = 0.5
    
    // ZOMBIE DETECTION
    FarAcquireRange = 600.0
    NearAcquireRange = 150.0
    FarAcquireTime = 4.0
    NearAcquireTime = 0.0
    ZombieSpawnRange = 1200.0
    ZombieDiscardRange = 2000
    
    // Wanderer behavior
    IntensityRelaxAllowWanderersThreshold = 0.05
    AlwaysAllowWanderers = false
    
    // PACING
    LockTempo = false
    RelaxMinInterval = 60
    RelaxMaxInterval = 90
    RelaxMaxFlowTravel = 600
    SustainPeakMinTime = 1
    SustainPeakMaxTime = 2
    IntensityRelaxThreshold = 0.5
    
    // DISABLE PANIC EVENTS
    AllowCrescendoEvents = false
    
    // MISCELLANEOUS
    cm_AllowPillConversion = false
    cm_AllowSurvivorRescue = false
    cm_NoSurvivorBots = true
    cm_ShouldHurry = false
    WaterSlowsMovement = false

    // BLOCK ITEM SPAWNS
    FirstAidItem = 0
    PillsItem = 0
    MolotovItem = 0
    PipeBombItem = 0
    VomitJarItem = 0
    AdrenalItem = 0
    DefibrillatorItem = 0
    UpgradePackItem = 0
    PrimaryWeaponItem = 0
    SecondaryWeaponItem = 0
    MeleeWeaponItem = 100
}

//------------------------------------------------------------------------------
// MUTATION STATE
//------------------------------------------------------------------------------
MutationState <-
{
    AmmoInitialized = false
}

//------------------------------------------------------------------------------
// MELEE WEAPON TIERS
//------------------------------------------------------------------------------
tier1Melee <- {
    katana = true
    machete = true
    fireaxe = true
    chainsaw = true
}

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

tier3Melee <- {
    frying_pan = true
    tonfa = true
}

//------------------------------------------------------------------------------
// WEAPONS TO REMOVE
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

    // All guns (magnum is given at spawn, standard pistol has 0 damage via weapon script)
    weapon_pistol = 0
    weapon_pistol_spawn = 0
    weapon_pistol_magnum = 0       // Block additional spawns
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
    weapon_hunting_rifle = 0
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
// RemoveUnwantedItems
//------------------------------------------------------------------------------
function RemoveUnwantedItems()
{
    Msg("Survival Horror: Starting aggressive item removal...\n")
    local removeCount = 0
    
    foreach (weaponClass, _ in weaponsToRemove)
    {
        EntFire(weaponClass, "Kill")
        
        local ent = null
        while ((ent = Entities.FindByClassname(ent, weaponClass)) != null)
        {
            ent.Kill()
            removeCount++
        }
    }
    
    EntFire("weapon_spawn", "Kill")
    EntFire("weapon_item_spawn", "Kill")
    
    Msg("Survival Horror: Removed " + removeCount + " items from map\n")
}

//------------------------------------------------------------------------------
// SetupPlayerLoadout - Give Magnum with limited ammo
// NOTE: The Magnum now uses AMMO_TYPE_HUNTINGRIFLE via weapon script,
// so reserve ammo is controlled by ammo_huntingrifle_max (set to 6)
//------------------------------------------------------------------------------
function SetupPlayerLoadout(player)
{
    if (player == null) return
    if (!player.IsValid()) return
    
    try {
        Msg("Survival Horror: Setting up loadout for player\n")
        
        // Strip ALL weapons first
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
        
        // Give the Magnum (which now has limited ammo via weapon script!)
        player.GiveItem("pistol_magnum")
        Msg("Survival Horror: Gave pistol_magnum (limited ammo version)\n")
        
        // Finalize ammo after weapon equips
        DoEntFire("!self", "RunScriptCode", "FinalizePlayerAmmo(GetPlayerFromUserID(" + player.GetPlayerUserId() + "))", 0.1, null, null)
    }
    catch (e)
    {
        Msg("Survival Horror: Error in SetupPlayerLoadout: " + e + "\n")
    }
}

//------------------------------------------------------------------------------
// FinalizePlayerAmmo - Ensure magnum has correct ammo
//------------------------------------------------------------------------------
function FinalizePlayerAmmo(player)
{
    if (player == null) return
    if (!player.IsValid()) return
    
    try {
        // Find magnum and set clip
        for (local i = 0; i < 6; i++)
        {
            local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
            if (weapon != null && weapon.IsValid() && weapon.GetClassname() == "weapon_pistol_magnum")
            {
                weapon.SetClip1(MAGNUM_CLIP)
                Msg("Survival Horror: Set magnum clip to " + MAGNUM_CLIP + " rounds\n")
                break
            }
        }
        
        // The reserve ammo is automatically set by ammo_huntingrifle_max (6)
        // because the weapon script changed the Magnum's ammo type
        Msg("Survival Horror: Magnum ammo setup complete (6 clip + 6 reserve = 12 total)\n")
    }
    catch (e)
    {
        Msg("Survival Horror: Error in FinalizePlayerAmmo: " + e + "\n")
    }
}

//------------------------------------------------------------------------------
// KickAllSurvivorBots
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
// CountInfected
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
// CullZombiesToTarget
//------------------------------------------------------------------------------
function CullZombiesToTarget(targetCount)
{
    Msg("Survival Horror: Starting cluster-aware zombie culling...\n")
    
    local zombies = []
    local ent = null
    while ((ent = Entities.FindByClassname(ent, "infected")) != null)
    {
        if (ent.IsValid())
            zombies.append(ent)
    }
    
    local currentCount = zombies.len()
    Msg("Survival Horror: Found " + currentCount + " zombies on map\n")
    
    if (currentCount <= targetCount)
    {
        Msg("Survival Horror: Count (" + currentCount + ") <= target (" + targetCount + "), no culling needed\n")
        return
    }
    
    local toDelete = currentCount - targetCount
    Msg("Survival Horror: Need to cull " + toDelete + " zombies\n")
    
    local scored = []
    foreach (zombie in zombies)
    {
        local pos = zombie.GetOrigin()
        local clusterScore = 0
        
        foreach (other in zombies)
        {
            if (other == zombie) continue
            
            local dist = (other.GetOrigin() - pos).Length()
            
            if (dist < CLUSTER_DIST_VERY_CLOSE)
                clusterScore += 3
            else if (dist < CLUSTER_DIST_CLOSE)
                clusterScore += 2
            else if (dist < CLUSTER_DIST_NEARBY)
                clusterScore += 1
        }
        
        scored.append({ zombie = zombie, score = clusterScore })
    }
    
    scored.sort(function(a, b) {
        if (b.score > a.score) return 1
        if (b.score < a.score) return -1
        return 0
    })
    
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
// GetDefaultItem - Starting loadout: Magnum with limited ammo
// The standard pistol will also spawn but has 0 damage (weapon script)
//------------------------------------------------------------------------------
function GetDefaultItem(index)
{
    if (index == 0) return "pistol_magnum"  // Limited ammo Magnum
    return ""  // Block other slots
}

//------------------------------------------------------------------------------
// AllowWeaponSpawn
//------------------------------------------------------------------------------
function AllowWeaponSpawn(classname)
{
    if (classname in weaponsToRemove)
    {
        Msg("Survival Horror: Blocked spawn of " + classname + "\n")
        return false
    }

    if (classname == "weapon_melee") return true
    if (classname == "weapon_melee_spawn") return true
    if (classname.find("melee") != null) return true

    Msg("Survival Horror: Blocked unknown spawn: " + classname + "\n")
    return false
}

//------------------------------------------------------------------------------
// GetMeleeWeaponName
//------------------------------------------------------------------------------
function GetMeleeWeaponName(attacker)
{
    if (attacker == null) return ""

    try {
        local weapon = attacker.GetActiveWeapon()
        if (weapon != null)
        {
            if (weapon.GetClassname() == "weapon_melee")
            {
                local modelName = weapon.GetModelName()
                if (modelName != null)
                {
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
    } catch(e) {}

    return ""
}

//------------------------------------------------------------------------------
// GetMeleeTierMultiplier
//------------------------------------------------------------------------------
function GetMeleeTierMultiplier(weaponName)
{
    if (weaponName in tier1Melee) return 1.0
    if (weaponName in tier2Melee) return 0.5
    if (weaponName in tier3Melee) return 0.25
    return 0.5
}

//------------------------------------------------------------------------------
// AllowTakeDamage
//------------------------------------------------------------------------------
function AllowTakeDamage(dmgTable)
{
    if (!("Victim" in dmgTable)) return true
    if (dmgTable.Victim == null) return true

    local victim = dmgTable.Victim
    local attacker = ("Attacker" in dmgTable) ? dmgTable.Attacker : null
    local victimClass = victim.GetClassname()

    // DAMAGE TO INFECTED
    if (victimClass == "infected")
    {
        local hitgroup = ("Hitgroup" in dmgTable) ? dmgTable.Hitgroup : -1
        local dmgType = ("DamageType" in dmgTable) ? dmgTable.DamageType : 0
        local isHeadshot = (hitgroup == 1)

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

        if (!isMelee && ((dmgType & 4) || (dmgType & 128)))
        {
            isMelee = true
            weaponName = GetMeleeWeaponName(attacker)
        }

        if (isMelee)
        {
            local tierMultiplier = GetMeleeTierMultiplier(weaponName)
            local randomMultiplier = 0.25 + (RandomFloat(0.0, 1.0) * 0.75)
            
            dmgTable.DamageDone = dmgTable.DamageDone * tierMultiplier * randomMultiplier
            
            return true
        }
        else if (!isHeadshot)
        {
            // Gun body shot - block damage (headshots only)
            dmgTable.DamageDone = 0
            return true
        }
    }

    // SURVIVOR FRAGILITY
    if (victimClass == "player" || victimClass == "survivor_bot")
    {
        if (attacker != null && attacker.GetClassname() == "infected")
        {
            dmgTable.DamageDone = dmgTable.DamageDone * 5.0
        }
    }

    return true
}

//------------------------------------------------------------------------------
// EVENT HANDLERS
//------------------------------------------------------------------------------
function OnGameEvent_round_start(params)
{
    Msg("Survival Horror: Round starting...\n")

    RemoveUnwantedItems()

    Convars.SetValue("mp_friendlyfire", 1)
    Convars.SetValue("ammo_huntingrifle_max", MAGNUM_RESERVE)  // Controls Magnum reserve!
    Convars.SetValue("survivor_respawn_with_guns", 0)
    Convars.SetValue("director_no_mobs", 1)
    Convars.SetValue("z_common_limit", ZOMBIE_TARGET_COUNT)
    
    MutationState.AmmoInitialized = false
    
    DoEntFire("!self", "RunScriptCode", "KickAllSurvivorBots()", 1.0, null, null)
    DoEntFire("!self", "RunScriptCode", "CullZombiesToTarget(" + ZOMBIE_TARGET_COUNT + ")", ZOMBIE_CULL_DELAY, null, null)
}

function OnGameEvent_player_spawn(params)
{
    local player = GetPlayerFromUserID(params.userid)
    if (player == null) return
    
    try {
        if (IsPlayerABot(player)) return
    } catch (e) {}
    
    DoEntFire("!self", "RunScriptCode", "SetupPlayerLoadout(GetPlayerFromUserID(" + params.userid + "))", 1.0, null, null)
}

function OnGameEvent_ammo_pickup(params)
{
    // With the weapon script approach, ammo pickups are limited by ammo_huntingrifle_max
    // But we block ammo spawns anyway, so this is just a safety net
    local player = GetPlayerFromUserID(params.userid)
    if (player == null) return
    
    Msg("Survival Horror: Player picked up ammo (should be blocked by spawn rules)\n")
}

function OnGameEvent_infected_spawn(params)
{
    local count = CountInfected()
    if (count > ZOMBIE_TARGET_COUNT)
    {
        Msg("Survival Horror: Zombie count (" + count + ") exceeds target, culling...\n")
        CullZombiesToTarget(ZOMBIE_TARGET_COUNT)
    }
}

function OnGameEvent_player_incapacitated(params)
{
    Msg("Survival Horror: A survivor has fallen!\n")
}

function OnGameEvent_round_start_post_nav(params)
{
    Msg("Survival Horror: Map loaded, preparing horror...\n")

    RemoveUnwantedItems()
    
    DoEntFire("!self", "RunScriptCode", "RemoveUnwantedItems()", 5.0, null, null)
    DoEntFire("!self", "RunScriptCode", "RemoveUnwantedItems()", 10.0, null, null)
}

function OnGameEvent_player_first_spawn(params)
{
    ClientPrint(null, 3, "=== SURVIVAL HORROR ===")
    ClientPrint(null, 3, "Headshots only. Magnum: 6 bullets + 6 reserve.")
    ClientPrint(null, 3, "Move carefully. Hide or die.")
}

//------------------------------------------------------------------------------
// FINAL INITIALIZATION
//------------------------------------------------------------------------------
RegisterCallbacks()

if (!("MutationOptions" in getroottable()))
{
    getroottable().MutationOptions <- MutationOptions
    Msg("Survival Horror: MutationOptions registered\n")
}

__CollectEventCallbacks(this, "OnGameEvent_", "GameEventCallbacks", RegisterScriptGameEventListener)
Msg("Survival Horror: Game event callbacks collected\n")

ApplyConvarSettings()

Msg("Survival Horror Mutation Script Initialized!\n")
Msg("=== SURVIVAL HORROR ACTIVE ===\n")
Msg("HUMANS ONLY - AI bots will be kicked.\n")
Msg("Headshots only for GUNS. Melee has random damage (25%-100% per tier).\n")
Msg("Magnum with 12 rounds total (6 clip + 6 reserve). Limited ammo!\n")
Msg("Standard pistol does 0 damage (weapon script override).\n")
Msg("Max 80 zombies, culled by clusters.\n")
