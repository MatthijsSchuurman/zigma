const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

const ComponentLight = @import("../components/light.zig");

const Light = struct {
  active: bool = true,
  type: ComponentLight.LightType = .Point,

  target: struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
  } = .{},
};

pub fn init(entity: ent.Entity, params: Light) ent.Entity {
  if (entity.world.components.light.getPtr(entity.id)) |_|
    return entity;

  const new = ComponentLight.Component{
    .active = params.active,
    .type = params.type,
    .target = .{.x = params.target.x, .y = params.target.y, .z = params.target.z},
  };
  entity.world.components.light.put(entity.id, new) catch @panic("Failed to store light");

  _ = entity
  .position(-5, 2, 5)
  .color(255, 255, 255, 255);

  return entity;
}

pub fn activate(entity: ent.Entity) ent.Entity {
  var it = entity.world.components.light.iterator();

  while(it.next()) |entry| //Ensure only this light is active
    entry.value_ptr.*.active = entry.key_ptr.* == entity.id;

  return entity;
}

pub fn deactivate(entity: ent.Entity) ent.Entity {
  if (entity.world.components.light.getPtr(entity.id)) |light|
    light.active = false;

  return entity;
}

pub fn target(entity: ent.Entity, x: f32, y: f32, z: f32) ent.Entity {
  if (entity.world.components.light.getPtr(entity.id)) |light|
    light.target = .{.x = x, .y = y, .z = z };

  return entity;
}

// Testing
const tst = std.testing;

test "Component should init light" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = init(entity, .{});

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.light.get(entity.id)) |light|
    try tst.expectEqual(ComponentLight.Component{.active = true, .type = .Point, .target = .{.x = 0, .y = 0, .z = 0}}, light)
  else
    return error.TestExpectedCamera;

  if (world.components.position.get(entity.id)) |position|
    try tst.expectEqual(ecs.Components.Position.Component{.x = -5, .y = 2, .z = 5}, position)
  else
    return error.TestExpectedPosition;

  if (world.components.color.get(entity.id)) |color|
    try tst.expectEqual(ecs.Components.Color.Component{.r = 255, .g = 255, .b = 255, .a = 255}, color)
  else
    return error.TestExpectedColor;
}

test "Component should activate light" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test").light(.{.active = false});

  if (world.components.light.get(entity.id)) |light|
    try tst.expectEqual(ComponentLight.Component{.active = false, .type = .Point, .target = .{.x = 0, .y = 0, .z = 0}}, light)
  else
    return error.TestExpectedCamera;

  // When
  const result = activate(entity);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.light.get(entity.id)) |light|
    try tst.expectEqual(ComponentLight.Component{.active = true, .type = .Point, .target = .{.x = 0, .y = 0, .z = 0}}, light)
  else
    return error.TestExpectedCamera;
}

test "Component should deactivate light" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test").light(.{});

  // When
  const result = deactivate(entity);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.light.get(entity.id)) |light|
    try tst.expectEqual(ComponentLight.Component{.active = false, .type = .Point, .target = .{.x = 0, .y = 0, .z = 0}}, light)
  else
    return error.TestExpectedCamera;
}

test "Component should set target" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test").light(.{});

  // When
  const result = target(entity, 1, 2, 3);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.light.get(entity.id)) |light|
    try tst.expectEqual(ComponentLight.Component{.active = true, .type = .Point, .target = .{.x = 1, .y = 2, .z = 3}}, light)
  else
    return error.TestExpectedCamera;
}
