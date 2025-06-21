const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");

pub const Component = struct {
  text: []const u8,
};

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

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ent.EntityID {
    return world.query(Query, &world.components.text, f, sort);
  }
};


// Testing
const tst = std.testing;
const EntityText = @import("entity.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity1 = EntityText.set(world.entity("test1"), "test1");
  _ = EntityText.set(world.entity("test2"), "test2");

  // When
  const result = Query.exec(&world, .{ .text = .{ .eq = "test1" }}, &.{.text_asc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
