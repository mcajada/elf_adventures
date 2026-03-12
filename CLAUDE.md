# Elf Adventure - Godot 4.6 Project

## Run the game

```bash
DISPLAY=:0 /tmp/Godot_v4.6.1-stable_linux.x86_64 --rendering-driver opengl3 --path /workspace/godot_test
```

### First-time setup (download Godot)

```bash
cd /tmp && wget -q https://github.com/godotengine/godot/releases/download/4.6.1-stable/Godot_v4.6.1-stable_linux.x86_64.zip -O godot.zip && unzip -o godot.zip
```

### Headless import (no display needed)

```bash
/tmp/Godot_v4.6.1-stable_linux.x86_64 --headless --import --path /workspace/godot_test
```

## Notes

- Uses GL Compatibility renderer (no Vulkan/DRI3 on this machine)
- `DISPLAY=:0` is required — the shell doesn't set it by default
- Sprite atlas parts use `rotation = -1.5708` for rotated textures — do NOT flip `scale.x` for directional facing (it breaks rotated sprites)
