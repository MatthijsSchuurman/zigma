# Zigma demo engine

A minimal, modular Zig + Raylib framework for building audiovisual demos on Linux.

## Features

- **Entity Component System (ECS):**
  Lightweight ECS implementation for organizing logic and effects

- **Variable Timelines:**
  Work with multiple timelines all with different speeds and direction of time

- **Event-Driven Components:**
  Components can be attached to timelines by events for realtime mutation

- **Raylib Backend:**
  Hardware-accelerated 2D/3D graphics and audio via Raylib.

## Requirements

- Zig 0.13 or newer
- Raylib (linked dynamically or statically)
- Linux

## Build

```sh
zig build run
```
