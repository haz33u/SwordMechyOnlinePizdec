# Detailed Component Structure Analysis: HinataEVO & ItachiEVO NPCs

## 1. Overview & General Composition
Both `HinataEVO` and `ItachiEVO` are modular anime-style R6 NPC models from the `Anime Expeditions` place file (`place 84515722934860`). They are engineered as full-featured combat / interactive NPCs with custom welded attachments, custom anime face decals, hair MeshParts, aura emitters, and weapon holsters.

---

## 2. Model Structure: `ItachiEVO`

### A. Core Base R6 Humanoid Parts:
- **`Humanoid`** (Class: `Humanoid`): Controls NPC health, animation track playback, hip height, and display name.
- **`HumanoidRootPart`** (Class: `Part`): Root CFrame anchor part (`CanCollide = false`, `Transparency = 1`).
- **`Head`** (Class: `Part`): Base head mesh + Face Decal (`rbxassetid://...`).
- **`Torso`** (Class: `Part`): Main upper torso part holding Motor6D joints and accessory welds.
- **`Left Arm` & `Right Arm`** (Class: `Part`): Arm limbs with custom sleeve textures.
- **`Left Leg` & `Right Leg`** (Class: `Part`): Leg limbs with custom sandals/pants textures.

### B. Custom Anime Visual MeshParts & Accessories:
- **`Akatsuki Cloak` / `Coat`** (Class: `MeshPart` / `Accessory`): High-poly 3D Akatsuki cloak model attached to `Torso` via `WeldConstraint`.
- **`Itachi Hair`** (Class: `MeshPart`): Anime ponytail black hair model welded to `Head`.
- **`Sharingan Face / Eyes`** (Class: `Decal` / `BillboardGui`): Custom Sharingan eye texture overlaid on Head.
- **`Headband`** (Class: `MeshPart`): Leaf Village slashed headband accessory welded to `Head`.

### C. Visual Effects & Particles (VFX):
- **`CrowAura`** (Class: `ParticleEmitter`): Black crow feathers and shadow aura particles emitting from `HumanoidRootPart`.
- **`Amaterasu Flame`** (Class: `ParticleEmitter`): Black fire particles attached to eyes/hands.
- **`ToWeld` Folder** (Class: `Folder`): Holds un-welded prop accessories that are dynamically welded via script at runtime.

### D. Server Logic & Scripts:
- **`Animate`** (Class: `LocalScript` / `Script`): Controls custom idle stance, walking, and attack animations.
- **`ClickDetector` / `ProximityPrompt`**: Allows player interaction (dialogue, quest, or targeting).

---

## 3. Model Structure: `HinataEVO`

### A. Core Base R6 Humanoid Parts:
- **`Humanoid`**: Manages NPC state, animation tracks, and health.
- **`HumanoidRootPart`**: Root CFrame anchor.
- **`Head`**: Base head mesh + Custom Byakugan eyes texture.
- **`Torso`**, **`Left Arm`**, **`Right Arm`**, **`Left Leg`**, **`Right Leg`**: Body limbs with custom Hyuga jacket textures.

### B. Custom Anime Visual MeshParts & Accessories:
- **`Hinata Long Hair`** (Class: `MeshPart`): Dark purple long anime hair welded to `Head`.
- **`Hyuga Jacket`** (Class: `MeshPart` / `Accessory`): 3D anime coat welded to `Torso`.
- **`Chakra Palms`** (Class: `MeshPart`): Blue chakra aura mesh attachments on both hands.
- **`Byakugan Veins`** (Class: `Decal`): Vein textures around eyes.

### C. Visual Effects & Particles (VFX):
- **`TwinLionPalms`** (Class: `ParticleEmitter` / `SpecialMesh`): Blue twin lion chakra heads attached to hands.
- **`Chakra Aura`** (Class: `ParticleEmitter`): Soft blue glowing particles around the body.

---

## 4. Key Takeaways for Our NPC Architecture:
1. **Single PrimaryPart (`HumanoidRootPart`):** All 3D accessories (hair, coats, weapons) are attached via `WeldConstraint` or `Weld` to `HumanoidRootPart` or `Torso`.
2. **Dynamic Weld Folder (`ToWeld`):** Loose weapons and props are kept inside a `ToWeld` folder and welded on spawn so models never fall apart.
3. **No Collision on Accessories:** All MeshPart accessories have `CanCollide = false` to prevent physics glitches and floating!
