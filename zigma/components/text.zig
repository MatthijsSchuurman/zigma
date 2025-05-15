const std = @import("std");
const ecs = @import("../ecs.zig");

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

  _ = entity
  .position(0, 0, 0)
  .rotation(0, 0, 0)
  .scale(1, 1, 1)
  .color(255, 255, 255, 255);

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
        .text_asc => std.mem.order(u8, a.text, b.text),
        .text_desc => std.mem.order(u8, b.text, a.text),
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ecs.EntityID {
    return world.query(Query, &world.components.text, f, sort);
  }
};


// Testing
const tst = std.testing;

test "Component should set text" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity = world.entity("test");

  // When
  const result = set(entity, "test");

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.text.get(entity.id)) |text|
    try tst.expectEqual(Component{.text = "test"}, text)
  else
    return error.TestExpectedText;

  if (world.components.position.get(entity.id)) |position|
    try tst.expectEqual(ecs.Components.Position.Component{.x = 0, .y = 0, .z = 0}, position)
  else
    return error.TestExpectedPosition;

  if (world.components.rotation.get(entity.id)) |rotation|
    try tst.expectEqual(ecs.Components.Rotation.Component{.x = 0, .y = 0, .z = 0}, rotation)
  else
    return error.TestExpectedRotation;

  if (world.components.scale.get(entity.id)) |scale|
    try tst.expectEqual(ecs.Components.Scale.Component{.x = 1, .y = 1, .z = 1}, scale)
  else
    return error.TestExpectedScale;

  if (world.components.color.get(entity.id)) |color|
    try tst.expectEqual(ecs.Components.Color.Component{.r = 255, .g = 255, .b = 255, .a = 255}, color)
  else
    return error.TestExpectedColor;
}

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity1 = set(world.entity("test1"), "test1");
  _ = set(world.entity("test2"), "test2");

  // When
  const result = Query.exec(&world, .{ .text = .{ .eq = "test1" }}, &.{.text_asc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
