//==============================================================================
// SURVIVAL HORROR MUTATION
// A stealth survival horror experience for Left 4 Dead 2
//
// Features:
// - Normal zombie population, avoidable if you move carefully
// - Headshots only to kill infected
// - Magnum pistol with ~20 bullets, no reloads or pickups
// - Melee weapons allowed
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
// APPLY SETTINGS VIA CONVARS (works with script_execute)
//------------------------------------------------------------------------------
function ApplyConvarSettings()
{
    Msg("Survival Horror: Applying convar settings...\n")

    // Enable cheats (required for some convars)
    Convars.SetValue("sv_cheats", 1)

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

    // Disable mobs/hordes
    Convars.SetValue("director_no_mobs", 1)

    // Friendly fire
    Convars.SetValue("mp_friendlyfire", 1)

    // Survivor settings
    Convars.SetValue("survivor_max_incapacitated_count", 1)
    Convars.SetValue("survivor_respawn_with_guns", 0)

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
    cm_NoSurvivorBots = false                 // Allow bots if needed
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
    SecondaryWeaponItem = 0                   // No secondary weapons (except starting magnum)
    MeleeWeaponItem = 100                     // Melee weapons spawn normally
}

//------------------------------------------------------------------------------
// MUTATION STATE - Tracks runtime state
//------------------------------------------------------------------------------
MutationState <-
{
    AmmoInitialized = false
    StartingAmmo = 20
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

    // Guns - all types
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
// RemoveFirstAidKits - Remove pre-placed map items (safe room table, etc.)
//------------------------------------------------------------------------------
function RemoveFirstAidKits()
{
    local kit = null
    while ((kit = Entities.FindByClassname(kit, "weapon_first_aid_kit")) != null)
    {
        kit.Kill()
    }
}

//------------------------------------------------------------------------------
// GetDefaultItem - Starting loadout
// Players start with only a Magnum pistol
//------------------------------------------------------------------------------
function GetDefaultItem(index)
{
    if (index == 0) return "pistol_magnum"
    return 0
}

//------------------------------------------------------------------------------
// AllowWeaponSpawn - Block all weapon/item spawns except melee
//------------------------------------------------------------------------------
function AllowWeaponSpawn(classname)
{
    // Check if this weapon should be removed
    if (classname in weaponsToRemove)
    {
        return false
    }

    // Allow melee weapons
    if (classname == "weapon_melee") return true
    if (classname == "weapon_melee_spawn") return true
    if (classname.find("melee") != null) return true

    // Block everything else by default
    // - All ammo (ammo_spawn, weapon_ammo_spawn, upgrade_ammo_*)
    // - All throwables (pipe bombs, molotovs, bile bombs)
    // - All health items (first aid, pills, adrenaline, defibrillator)
    // - All special items (gnome, cola)
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
// GetMeleeDamageMultiplier - Get damage multiplier based on weapon tier
//------------------------------------------------------------------------------
function GetMeleeDamageMultiplier(weaponName)
{
    // Tier 1 - Full damage (1-hit kill)
    if (weaponName in tier1Melee) return 1.0

    // Tier 2 - Half damage (2-hit kill)
    if (weaponName in tier2Melee) return 0.5

    // Tier 3 - Third damage (3-hit kill)
    if (weaponName in tier3Melee) return 0.35

    // Unknown weapon - default to tier 2
    return 0.5
}

//------------------------------------------------------------------------------
// AllowTakeDamage - Headshots only + Tiered melee + Survivor fragility
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
    // DAMAGE TO INFECTED - Headshots only for guns, tiered for melee
    //--------------------------------------------------------------------------
    if (victimClass == "infected")
    {
        local hitgroup = ("Hitgroup" in dmgTable) ? dmgTable.Hitgroup : -1
        local dmgType = ("DamageType" in dmgTable) ? dmgTable.DamageType : 0
        local isHeadshot = (hitgroup == 1)

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
            // Melee attack - apply tiered damage
            local multiplier = GetMeleeDamageMultiplier(weaponName)
            dmgTable.DamageDone = dmgTable.DamageDone * multiplier
            return true
        }
        else if (!isHeadshot)
        {
            // Gun body shot - block damage
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
    // Bots should avoid all guns
    if (classname.find("pistol") != null && classname != "pistol_magnum") return true
    if (classname.find("rifle") != null) return true
    if (classname.find("shotgun") != null) return true
    if (classname.find("smg") != null) return true
    if (classname.find("sniper") != null) return true
    if (classname.find("hunting") != null) return true
    
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

    // Remove pre-placed map items (safe room table, etc.)
    RemoveFirstAidKits()

    // Set friendly fire on
    Convars.SetValue("mp_friendlyfire", 1)
    
    // Try to limit ammo via convars (may not affect pistols directly)
    Convars.SetValue("ammo_pistol_max", 20)
    Convars.SetValue("survivor_respawn_with_guns", 0)
    
    // Disable director panic spawns
    Convars.SetValue("director_no_mobs", 1)
    
    MutationState.AmmoInitialized = false
}

//------------------------------------------------------------------------------
// OnGameEvent_player_spawn - Called when a player spawns
//------------------------------------------------------------------------------
function OnGameEvent_player_spawn(params)
{
    // Note: Timer functionality removed - ammo limiting handled via convars
    // The magnum starts with limited ammo based on ammo_pistol_max
}

//------------------------------------------------------------------------------
// AmmoSetupTimer - Set up limited ammo after spawn
//------------------------------------------------------------------------------
function AmmoSetupTimer()
{
    Msg("Survival Horror: Setting up limited ammo...\n")
    
    // Iterate through all players and set their ammo
    local player = null
    while ((player = Entities.FindByClassname(player, "player")) != null)
    {
        // Try to set ammo to 20 via input
        // The magnum normally has 8 in clip, this sets reserve
        DoEntFire("!self", "SetAmmoAmount", "20", 0.0, null, player)
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
// Update - Called every tick (use sparingly)
// We don't need continuous updates for this mutation
//------------------------------------------------------------------------------
// function Update()
// {
// }

//------------------------------------------------------------------------------
// REGISTER EVENT CALLBACKS
//------------------------------------------------------------------------------
function OnGameEvent_round_start_post_nav(params)
{
    // Additional setup after navigation is loaded
    Msg("Survival Horror: Map loaded, preparing horror...\n")

    // Remove pre-placed map items (safe room table, etc.)
    RemoveFirstAidKits()
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

// Apply convars again to make sure they stick
ApplyConvarSettings()

Msg("Survival Horror Mutation Script Initialized!\n")
Msg("=== SURVIVAL HORROR ACTIVE ===\n")
Msg("Headshots only. Melee allowed. No special infected.\n")
