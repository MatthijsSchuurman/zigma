const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

pub const Component = struct {
  type: []const u8,
  model: rl.Model,
  material_id: ent.EntityID = 0,
  hidden: bool = false,
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    type: ?ecs.FieldFilter([]const u8) = null,
    material_id: ?ecs.FieldFilter(ent.EntityID) = null,

    hidden: ?ecs.FieldFilter(bool) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.type) |cond|
      if (!ecs.matchField([]const u8, self.type, cond))
        return false;

    if (f.material_id) |cond|
      if (!ecs.matchField(ent.EntityID, self.material_id, cond))
        return false;

    if (f.hidden) |cond|
      if (!ecs.matchField(bool, self.hidden, cond))
        return false;

    return true;
  }

  pub const Sort = enum {
    type_asc,
    type_desc,
    material_id_asc,
    material_id_desc,
  };

  pub fn compare(a: Data, b: Data, sort: []const Sort) std.math.Order {
    for (sort) |field| {
      const order = switch (field) {
        .type_asc => std.mem.order(u8, a.type, b.type),
        .type_desc => std.mem.order(u8, b.type, a.type),
        .material_id_asc => std.math.order(a.material_id, b.material_id),
        .material_id_desc => std.math.order(b.material_id, a.material_id),
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ent.EntityID {
    return world.query(Query, &world.components.model, f, sort);
  }
};


// Testing
const tst = std.testing;
const EntityModel = @import("../entity/model.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity1 = EntityModel.init(world.entity("test1"), .{.type = "cube"});
  _ = EntityModel.init(world.entity("test2"), .{.type = "sphere"});

  // When
  const result = Query.exec(&world, .{ .type = .{ .eq = "cube" }}, &.{.type_asc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
