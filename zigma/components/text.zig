const ecs = @import("../ecs.zig");
const std = @import("std");

pub const Component = struct {
  text: []const u8,
};

pub fn set(entity: ecs.Entity, text: []const u8) ecs.Entity {
  if (entity.world.components.text.getPtr(entity.id)) |existing| {
    existing.* = .{.text = text};
    return entity;
  }

  const new = .{.text = text};

  entity.world.components.text.put(entity.id, new) catch @panic("Failed to store text");
  return entity;
}

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    text: ?ecs.FieldFilter([]const u8) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.text) |cond|
      if (!ecs.matchField([]const u8, self.text, cond))
        return false;

    return true;
  }

  pub const Sort = enum {
    text_asc,
    text_desc,
  };

  pub fn compare(a: Data, b: Data, sort: []const Sort) std.math.Order {
    for (sort) |field| {
      const order = switch (field) {
        .text_asc => std.math.order(a.text, b.text),
        .text_desc => std.math.order(b.text, a.text),
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn query(world: *ecs.World, f: Filter, sort: []const Sort) []ecs.EntityID {
    return world.query(Query, &world.components.text, f, sort);
  }
};
