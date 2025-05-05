const ecs = @import("../ecs.zig");

pub const Data = struct {
  x: f32,
  y: f32,
  z: f32,

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
};

pub fn query(world: *ecs.World, filter: Data.Filter) []ecs.EntityID {
  return world.query(Data, &world.components.position, filter, .{});
}

pub fn set(entity: ecs.Entity, x: f32, y: f32, z: f32) ecs.Entity {
  if (entity.world.components.position.getPtr(entity.id)) |existing| {
    existing.* = .{.x = x, .y = y, .z = z};
    return entity;
  }

  const new = .{.x = x, .y = y, .z = z };

  entity.world.components.position.put(entity.id, new) catch @panic("Failed to store position");
  return entity;
}
