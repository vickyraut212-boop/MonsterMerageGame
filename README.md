# Monster Merge

A 2D drop-and-merge physics puzzle game made with Godot 4. Drop monsters into a jar; two of the same tier merge into the next tier, up to the Tier 7 boss.

## Open the project
1. Install Godot 4.3 or newer (standard version, not .NET).
2. In Godot's Project Manager, click **Import** and pick `project.godot` in this folder.
3. Press **F5** to run. The Output panel says whether all 7 sprites were found.

## Folders
- `assets/monsters/` - the 7 monster PNGs (`tier_1.png` to `tier_7.png`)
- `scenes/` - Godot scenes (`main.tscn` is the game screen)
- `scripts/` - GDScript code
  - `tier_data.gd` - sizes and points for each tier (edit this to tune)
  - `main.gd` - the main game scene

## Roadmap
1. Project setup (this step)
2. Jar walls and the game-over line
3. Monster scene and the dropper
4. Merging, score and game over
