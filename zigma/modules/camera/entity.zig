const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

const Module = @import("module.zig").Module;

pub const Camera = struct {
  fovy: f32 = 45.0,

  target: struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
  } = .{},
};

pub fn init(entity: ent.Entity, params: Camera) ent.Entity {
  if (entity.world.components.camera.getPtr(entity.id)) |_|
    return entity;

  const is_first = entity.world.components.camera.count() == 0;
  const new = Module.Components.Camera.Component{
    .active = is_first,
    .target = .{.x = params.target.x, .y = params.target.y, .z = params.target.z},
    .fovy = params.fovy,
  };
  entity.world.components.camera.put(entity.id, new) catch @panic("Failed to store camera");

  _ = entity
  .position(5, 2, 5)
  .rotation(0, 1, 0); //aka up

  return entity;
}

pub fn activate(entity: ent.Entity) ent.Entity {
  var it = entity.world.components.camera.iterator();
  while(it.next()) |entry| //Ensure only this camera is active
    entry.value_ptr.*.active = entry.key_ptr.* == entity.id;

  return entity;
}

pub fn deactivate(entity: ent.Entity) ent.Entity {
  if (entity.world.components.camera.getPtr(entity.id)) |camera|
    camera.active = false;

  return entity;
}

pub fn target(entity: ent.Entity, x: f32, y: f32, z: f32) ent.Entity {
  if (entity.world.components.camera.getPtr(entity.id)) |camera|
    camera.target = .{.x = x, .y = y, .z = z };

  return entity;
}

pub fn fovy(entity: ent.Entity, value: f32) ent.Entity {
  if (entity.world.components.camera.getPtr(entity.id)) |camera|
    camera.fovy = value;

  return entity;
}

// Testing
const tst = std.testing;

test "Component should init camera" {
  // Given
  const ModuleTransform = @import("../transform/module.zig").Module;

  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = init(entity, .{});

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.camera.get(entity.id)) |camera|
    try tst.expectEqual(Module.Components.Camera.Component{.active = true, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera)
  else
    return error.TestExpectedCamera;

  if (world.components.position.get(entity.id)) |position|
    try tst.expectEqual(ModuleTransform.Components.Position.Component{.x = 5, .y = 2, .z = 5}, position)
  else
    return error.TestExpectedPosition;

  if (world.components.rotation.get(entity.id)) |rotation|
    try tst.expectEqual(ModuleTransform.Components.Rotation.Component{.x = 0, .y = 1, .z = 0}, rotation)
  else
    return error.TestExpectedRotation;
}

test "Component should activate camera" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test").camera(.{});
  const entity2 = world.entity("test2").camera(.{});

  if (world.components.camera.get(entity.id)) |camera|
    try tst.expectEqual(Module.Components.Camera.Component{.active = true, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera)
  else
    return error.TestExpectedCamera;

  if (world.components.camera.get(entity2.id)) |camera|
    try tst.expectEqual(Module.Components.Camera.Component{.active = false, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera)
  else
    return error.TestExpectedCamera;

  // When
  const result = activate(entity2);

  // Then
  try tst.expectEqual(entity2.id, result.id);
  try tst.expectEqual(entity2.world, result.world);

  if (world.components.camera.get(entity.id)) |camera|
    try tst.expectEqual(Module.Components.Camera.Component{.active = false, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera)
  else
    return error.TestExpectedCamera;

  if (world.components.camera.get(entity2.id)) |camera|
    try tst.expectEqual(Module.Components.Camera.Component{.active = true, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera)
  else
    return error.TestExpectedCamera;
}

test "Component should deactivate camera" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test").camera(.{});
  const entity2 = world.entity("test2").camera(.{});

  // When
  const result = deactivate(entity);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.camera.get(entity.id)) |camera|
    try tst.expectEqual(Module.Components.Camera.Component{.active = false, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera)
  else
    return error.TestExpectedCamera;

  if (world.components.camera.get(entity2.id)) |camera|
    try tst.expectEqual(Module.Components.Camera.Component{.active = false, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera)
  else
    return error.TestExpectedCamera;
}

test "Component should set fovy" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test").camera(.{});

  // When
  const result = fovy(entity, 90);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.camera.get(entity.id)) |camera|
    try tst.expectEqual(Module.Components.Camera.Component{.active = true, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 90.0}, camera)
  else
    return error.TestExpectedCamera;
}

test "Component should set target" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test").camera(.{});

  // When
  const result = target(entity, 1, 2, 3);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.camera.get(entity.id)) |camera|
    try tst.expectEqual(Module.Components.Camera.Component{.active = true, .target = .{.x = 1, .y = 2, .z = 3}, .fovy = 45.0}, camera)
  else
    return error.TestExpectedCamera;
}
