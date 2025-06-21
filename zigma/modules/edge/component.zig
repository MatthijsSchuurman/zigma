const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

pub const Component = struct {
  width: f32,
  color: rl.Color,
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    width: ?ecs.FieldFilter(f32) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.width) |cond|
      if (!ecs.matchField(f32, self.width, cond))
        return false;

    return true;
  }

  pub const Sort = enum {
    width_asc,
    width_desc,
  };

  pub fn compare(a: Data, b: Data, sort: []const Sort) std.math.Order {
    for (sort) |field| {
      const order = switch (field) {
        .width_asc => std.math.order(a.width, b.width),
        .width_desc => std.math.order(b.width, a.width),
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ent.EntityID {
    return world.query(Query, &world.components.edge, f, sort);
  }
};


// Testing
const tst = std.testing;
const ModuleModel = @import("../model/ecs.zig");
const EntityEdge = @import("entity.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity1 = ModuleModel.Entities.Model.init(world.entity("test1"), .{.type= "cube"});
  _ = EntityEdge.set(entity1, .{.width = 2});
  const entity2 = ModuleModel.Entities.Model.init(world.entity("test2"), .{.type = "cube"});
  _ = EntityEdge.set(entity2, .{.width = 1});

  // When
  const result = Query.exec(&world, .{ .width = .{ .eq = 2 }}, &.{.width_asc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
