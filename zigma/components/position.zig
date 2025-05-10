const std = @import("std");
const ecs = @import("../ecs.zig");

pub const Component = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub fn set(entity: ecs.Entity, x: f32, y: f32, z: f32) ecs.Entity {
  if (entity.world.components.position.getPtr(entity.id)) |existing| {
    existing.* = .{.x = x, .y = y, .z = z};
    return entity;
  }

  const new = .{.x = x, .y = y, .z = z };

  entity.world.components.position.put(entity.id, new) catch @panic("Failed to store position");
  return entity;
}

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    x: ?ecs.FieldFilter(f32) = null,
    y: ?ecs.FieldFilter(f32) = null,
    z: ?ecs.FieldFilter(f32) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.x) |cond|
      if (!ecs.matchField(f32, self.x, cond))
        return false;

    if (f.y) |cond|
      if (!ecs.matchField(f32, self.y, cond))
        return false;

    if (f.z) |cond|
      if (!ecs.matchField(f32, self.z, cond))
        return false;

    return true;
  }

  pub fn exec(world: *ecs.World, f: Filter) []ecs.EntityID {
    return world.query(Query, &world.components.position, f, .{});
  }
};


// Testing
const tst = std.testing;

test "Component Position should set value" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  const entity = world.entity("test");

  // When
  const result = entity.position(1, 2, 3);

  // Then
  try tst.expectEqual(result.id, entity.id);

  // Clean
  ecs.World.deinit(&world);
}
