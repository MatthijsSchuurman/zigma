const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

pub const Component = struct {
  type: []const u8,
  shader: rl.Shader,
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    type: ?ecs.FieldFilter([]const u8) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.type) |cond|
      if (!ecs.matchField([]const u8, self.type, cond))
        return false;

    return true;
  }

  pub const Sort = enum {
    type_asc,
    type_desc,
  };

  pub fn compare(a: Data, b: Data, sort: []const Sort) std.math.Order {
    for (sort) |field| {
      const order = switch (field) {
        .type_asc => std.mem.order(u8, a.type, b.type),
        .type_desc => std.mem.order(u8, b.type, a.type),
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ent.EntityID {
    return world.query(Query, &world.components.shader, f, sort);
  }
};


// Testing
const tst = std.testing;
const EntityShader = @import("entity.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity1 = EntityShader.init(world.entity("test1"), .{.type = "lighting"});
  _ = EntityShader.init(world.entity("test2"), .{.type = "test"});

  // When
  const result = Query.exec(&world, .{ .type = .{ .eq = "lighting" }}, &.{.type_asc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
