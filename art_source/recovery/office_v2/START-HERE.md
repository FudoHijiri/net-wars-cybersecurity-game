# NET WARS Recovery office

Extract the ZIP before giving it to Codex. Use `placement-blueprint.svg` as the map and the table below as the exact placement guide.

Coordinates are measured from the top-left of the 1536 × 1024 `art/office-background.png`. Each point is the **bottom center of the visible prop**, and width means visible artwork width. Transparent padding varies between PNGs. Account for it when aligning each sprite and keep its aspect ratio. If the backdrop is scaled in Godot, put the props under the same scaled parent. The rectangles in the SVG show approximate visual extents.

Keep the left entrance around (130, 415), the main aisle around y=420, and the connecting doorway at x=1135–1212 clear. Spawn at (170, 415). Keep an open route down through the doorway into the repair room.

| Mark | Asset | Placement | Bottom-center (x, y) | Width |
|---|---|---|---|---:|
| A | `dual-monitor-desk.png` | Monitoring 01 | (365, 362) | 135 px |
| B | `dual-monitor-desk.png` | Monitoring 02 | (545, 362) | 135 px |
| C | `access-terminal.png` | Access 01 | (740, 362) | 105 px |
| D | `access-terminal.png` | Access 02 | (905, 362) | 105 px |
| E | `printer-and-cabinet.png` | Printer cabinet | (1255, 362) | 85 px |
| F | `sofa-and-side-table.png` | Break corner | (244, 565) | 174 px |
| G | `server-rack.png` | Server 01 | (830, 805) | 65 px |
| H | `server-rack.png` | Server 02 | (930, 805) | 65 px |
| I | `server-rack.png` | Server 03 | (1030, 805) | 65 px |
| J | `network-switch.png` | Network switch | (875, 925) | 104 px |
| K | `backup-nas.png` | Backup storage | (1315, 805) | 100 px |
| L | `repair-workbench.png` | Repair bench | (1315, 925) | 145 px |

The plant, window, boards, and water cooler are part of the backdrop. The printer cabinet and break corner are decorative. The rack PNG is the base sprite and the GIF is its blinking reference. For the animated version, use the GIF timing and transparent frames in Godot. Align the visible rack edges so switching between static and animated art does not shift its position.

**Codex prompt**

C — Context  
This is the NET WARS Recovery office. Read the project Markdown and inspect the existing scenes. The attached ZIP contains the approved art, map and placement coordinates.

O — Objective  
Assemble the two-room office in Godot with editable props and short repair tasks.

R — Requirements  
Use the table as the placement source. Build the backdrop, props, collisions and interaction areas as editable scene nodes. Use one shared scene per equipment type and duplicate its instances as shown. Give each instance a unique ID. For each Day, choose affected equipment from that Day’s eligible groups once when Recovery begins. For example, randomly choose one of Server 01–03, keep the other two online and keep the choice fixed until the run ends. Opening or closing a task does not reroll it. Mark affected equipment with ! and repaired equipment with a check. Count each repair once.

C — Constraints  
Keep the entrance, aisle and doorway clear. Place interaction areas on the aisle side of each repairable prop, with the top row accessed from below and the lower office row from above. Leave the sofa and printer decorative. Use the supplied sprites and keep the positions editable in Godot. Keep task instructions short.

E — Expected Output  
Show the assembled room from the gameplay camera. Verify access to each repairable prop, the route between both rooms, and a run where only one of the three server copies needs repair.

**Required scene structure**

Create one reusable .tscn per equipment or furniture type. Put the sprite, solid collision, interaction area and status marker under that prop's Node2D root. The root sits at the bottom-center anchor. Use a StaticBody2D with a CollisionShape2D sized to the floor footprint and a separate Area2D with its own CollisionShape2D for interaction. All must move together when I drag the root. Keep the shapes editable in the Inspector. Decorative props need only the sprite and solid collision where appropriate.

Instance ServerRack.tscn three times inside the smaller IT room. Expose equipment ID and assigned task in the Inspector. Editing the shared scene should update all three copies, while moving one copy should move only that copy and its children. Keep interaction areas on the accessible side. For the rear server row and backup storage, approach from below. For the lower switch and workbench, approach from above.

Layout reference: https://www.ifma.org/media/cs3dae3n/relo-pdf-web.pdf
