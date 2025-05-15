const std = @import("std");
const ecs = @import("../ecs.zig");

pub const Component = struct {
  active: bool,

  target: struct {
    x: f32,
    y: f32,
    z: f32,
  },

  fovy: f32,
};

fn get(entity: ecs.Entity) *ecs.Components.Camera.Component {
  if (entity.world.components.camera.getPtr(entity.id)) |existing| {
    return existing;
  }

  const is_first = entity.world.components.camera.count() == 0;
  const new = entity.world.components.camera.getOrPut(entity.id) catch @panic("Failed to store camera");

  //ensure defaults are set
  new.value_ptr.* = .{
    .active = is_first,
    .target = .{.x = 0, .y = 0, .z = 0},
    .fovy = 45,
  };

  _ = entity.position(5, 2, 5)
  .rotation(0, 1, 0); //aka up

  return new.value_ptr;
}

pub fn target(entity: ecs.Entity, x: f32, y: f32, z: f32) ecs.Entity {
  const camera = get(entity);
  camera.*.target = .{.x = x, .y = y, .z = z };
  return entity;
}

pub fn fovy(entity: ecs.Entity, value: f32) ecs.Entity {
  const camera = get(entity);
  camera.*.fovy = value;
  return entity;
}

pub fn activate(entity: ecs.Entity) ecs.Entity {
  var it = entity.world.components.camera.iterator();

  while(it.next()) |entry| //Ensure only this camera is active
    entry.value_ptr.*.active = entry.key_ptr.* == entity.id;

  return entity;
}

pub fn deactivate(entity: ecs.Entity) ecs.Entity {
  const camera = get(entity);
  camera.*.active = false;
  return entity;
}

// Testing
const tst = std.testing;

test "Component should set camera" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = target(entity, 1, 2, 3);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.camera.get(entity.id)) |camera|
    try tst.expectEqual(Component{.active = true, .target = .{.x = 1, .y = 2, .z = 3}, .fovy = 45.0}, camera)
  else
    return error.TestExpectedCamera;

  if (world.components.position.get(entity.id)) |position|
    try tst.expectEqual(ecs.Components.Position.Component{.x = 5, .y = 2, .z = 5}, position)
  else
    return error.TestExpectedPosition;

  if (world.components.rotation.get(entity.id)) |rotation|
    try tst.expectEqual(ecs.Components.Rotation.Component{.x = 0, .y = 1, .z = 0}, rotation)
  else
    return error.TestExpectedRotation;
}

test "Component should set fovy" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = fovy(entity, 90);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.camera.get(entity.id)) |camera|
    try tst.expectEqual(Component{.active = true, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 90.0}, camera)
  else
    return error.TestExpectedCamera;

  if (world.components.position.get(entity.id)) |position|
    try tst.expectEqual(ecs.Components.Position.Component{.x = 5, .y = 2, .z = 5}, position)
  else
    return error.TestExpectedPosition;

  if (world.components.rotation.get(entity.id)) |rotation|
    try tst.expectEqual(ecs.Components.Rotation.Component{.x = 0, .y = 1, .z = 0}, rotation)
  else
    return error.TestExpectedRotation;
}

test "Component should activate camera" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");
  const entity2 = world.entity("test2");

  const camera = get(entity);
  const camera2 = get(entity2);
  try tst.expectEqual(Component{.active = true, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera.*);
  try tst.expectEqual(Component{.active = false, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera2.*);


  // When
  const result = activate(entity2);

  // Then
  try tst.expectEqual(entity2.id, result.id);
  try tst.expectEqual(entity2.world, result.world);

  try tst.expectEqual(Component{.active = false , .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera.*);
  try tst.expectEqual(Component{.active = true, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera2.*);
}

test "Component should deactivate camera" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");
  const entity2 = world.entity("test2");

  const camera = get(entity);
  const camera2 = get(entity2);

  // When
  const result = deactivate(entity);

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);
  try tst.expectEqual(Component{.active = false, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera.*);
  try tst.expectEqual(Component{.active = false, .target = .{.x = 0, .y = 0, .z = 0}, .fovy = 45.0}, camera2.*);
}
