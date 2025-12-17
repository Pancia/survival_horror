================================================================================
SURVIVAL HORROR MUTATION - Installation Guide
================================================================================

CONTENTS OF THIS FOLDER:
------------------------
survival_horror/
    addoninfo.txt           - Addon metadata
    README.txt              - This file
    scripts/
        vscripts/
            survival_horror.nut  - Main mutation script


================================================================================
INSTALLATION METHOD 1: Quick Test (No VPK)
================================================================================

For quick testing without packaging:

1. Navigate to your L4D2 installation:
   Steam\steamapps\common\Left 4 Dead 2\left4dead2\

2. Copy the "scripts" folder from this addon into that directory.
   Result: Steam\steamapps\common\Left 4 Dead 2\left4dead2\scripts\vscripts\survival_horror.nut

3. Launch L4D2

4. Open console (~) and type:
   map c1m1_hotel

5. Once the map loads, execute the script:
   script_execute survival_horror

6. You should see "Survival Horror Mutation Loaded" in console


================================================================================
INSTALLATION METHOD 2: VPK Addon (Recommended for Sharing)
================================================================================

To create a proper addon that appears in the game's addon menu:

1. Download and install Valve's VPK tool (comes with L4D2 Authoring Tools)
   - In Steam: Library > Tools > Left 4 Dead 2 Authoring Tools
   - Install it

2. Create the VPK:
   
   WINDOWS:
   - Open Command Prompt
   - Navigate to: Steam\steamapps\common\Left 4 Dead 2\bin\
   - Run: vpk.exe "C:\path\to\survival_horror"
   - This creates: survival_horror.vpk

   MAC/LINUX:
   - The vpk tool is in the bin folder
   - Run: ./vpk /path/to/survival_horror

3. Move the created survival_horror.vpk to:
   Steam\steamapps\common\Left 4 Dead 2\left4dead2\addons\

4. Launch L4D2

5. From the main menu, click "Add-ons"
   - Find and enable "Survival Horror"

6. Start a game:
   - Play > Play Campaign > Select any campaign
   - Change game mode to "Mutation"
   - In the mutation filter settings:
     * Set "Number of Players" to "Any"
     * Set "Mutation Type" to "Any"
   - Find and select "Survival Horror" from the mutations list

   OR use console:
   map c1m1_hotel survival_horror


================================================================================
CONSOLE COMMANDS FOR TESTING
================================================================================

Open console with ~ (tilde) key

# Start the mutation on Dead Center
map c1m1_hotel survival_horror

# Start on Dark Carnival
map c2m1_highway survival_horror

# Start on any map
map <mapname> survival_horror

# Restart the map
changelevel_keep_players c1m1_hotel

# Enable cheats for testing
sv_cheats 1

# Give yourself a melee weapon (for testing)
give katana
give machete
give fireaxe
give crowbar

# Check your ammo
give ammo    (this won't work with our mod - intentionally!)

# Script debug output automatically appears in console
# Look for lines starting with "Survival Horror:"


================================================================================
TROUBLESHOOTING
================================================================================

MUTATION DOESN'T LOAD AUTOMATICALLY:
- The "map <mapname> survival_horror" method requires the mutation to be
  registered with the game's mutation system (which requires additional files)
- For testing, load any map normally then manually execute:
  script_execute survival_horror
- Make sure the script file is named exactly "survival_horror.nut"
- Check console for error messages
- Verify file is in: left4dead2/scripts/vscripts/survival_horror.nut

ZOMBIES STILL SPAWNING NORMALLY:
- The script may not have loaded - run: script_execute survival_horror
- Check console for "Survival Horror Mutation Loaded" message

WEAPONS STILL SPAWNING:
- Some map-specific spawns may override
- This is a limitation of the scripting system

TOO HARD / TOO EASY:
- Edit survival_horror.nut
- Adjust CommonLimit (zombie count)
- Adjust FarAcquireRange (detection distance)
- Adjust damage multiplier in AllowTakeDamage function


================================================================================
CUSTOMIZATION
================================================================================

Edit survival_horror.nut to tweak:

ZOMBIE COUNT:
    CommonLimit = 12          // Increase for more zombies

DETECTION RANGE:
    FarAcquireRange = 600.0   // Increase = easier to be seen
    FarAcquireTime = 4.0      // Decrease = faster detection

PLAYER HEALTH:
    SurvivorMaxIncapacitatedCount = 1   // 0 = one down and dead
    
DAMAGE MULTIPLIER:
    In AllowTakeDamage function:
    dmgTable.DamageDone = dmgTable.DamageDone * 5.0  // Adjust multiplier


================================================================================
STEAM WORKSHOP PUBLISHING
================================================================================

To publish to Steam Workshop:

1. Create the VPK as described above

2. Create a 512x512 preview image (JPEG)
   - Save as: survival_horror.jpg
   - Place next to the .vpk file

3. Use the Workshop Manager:
   - Launch L4D2 Authoring Tools
   - Select "Left 4 Dead 2 Workshop Manager"
   - Create new addon
   - Select your .vpk file
   - Fill in title, description, tags
   - Publish!


================================================================================
CREDITS & LICENSE
================================================================================

Created with assistance from Claude AI
Feel free to modify and share!

Based on Left 4 Dead 2's VScript and Mutation system by Valve Corporation.


================================================================================
