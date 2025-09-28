const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

const Module = @import("module.zig").Module;

pub const Dirty = enum {
  position,
  rotation,
  scale,
  color,

  model,
  material,
  text,
};

pub fn set(entity: ent.Entity, flags: []const Dirty) ent.Entity {
  const entry = entity.world.components.dirty.getOrPut(entity.id) catch @panic("Failed to store dirty");

  if (!entry.found_existing)
    entry.value_ptr.* = Module.Components.Dirty.Component{};

  for (flags) |flag| {
    switch (flag) {
      .position => entry.value_ptr.position = true,
      .rotation => entry.value_ptr.rotation = true,
      .scale => entry.value_ptr.scale = true,
      .color => entry.value_ptr.color = true,

      .model => entry.value_ptr.model = true,
      .material => entry.value_ptr.material = true,
      .text => entry.value_ptr.text = true,
    }
  }

  return entity;
}


// Testing
const tst = std.testing;

test "Component should set dirty" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, &.{.position, .text});

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(Module.Components.Dirty.Component{
      .position = true,
      .rotation = false,
      .scale = false,
      .color = false,

      .model = false,
      .material = false,
      .text = true,
    }, dirty)
  else
    return error.TestExpectedDirty;
}
