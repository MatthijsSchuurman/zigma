const ecs = @import("../ecs.zig");

pub const Component = struct {
  r: u8,
  g: u8,
  b: u8,
  a: u8,

  pub const Filter = struct {
    r: ?ecs.FieldFilter(f32) = null,
    g: ?ecs.FieldFilter(f32) = null,
    b: ?ecs.FieldFilter(f32) = null,
    a: ?ecs.FieldFilter(f32) = null,
  };

  pub fn filter(self: Component, f: Filter) bool {
    if (f.r) |cond|
      if (!ecs.matchField(f32, self.r, cond))
        return false;

    if (f.g) |cond|
      if (!ecs.matchField(f32, self.g, cond))
        return false;

    if (f.b) |cond|
      if (!ecs.matchField(f32, self.b, cond))
        return false;

    if (f.a) |cond|
      if (!ecs.matchField(f32, self.a, cond))
        return false;

    return true;
  }
};

pub fn query(world: *ecs.World, filter: Component.Filter) []ecs.EntityID {
  return world.query(Component, &world.components.color, filter, .{});
}

pub fn set(entity: ecs.Entity, r: u8, g: u8, b: u8, a: u8) ecs.Entity {
  if (entity.world.components.color.getPtr(entity.id)) |existing| {
    existing.* = .{.r = r, .g = g, .b = b, .a = a };
    return entity;
  }

  const new = .{.r = r, .g = g, .b = b, .a = a };

  entity.world.components.color.put(entity.id, new) catch @panic("Failed to store color");
  return entity;
}
