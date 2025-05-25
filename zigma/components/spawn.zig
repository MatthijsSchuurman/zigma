const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

pub const Component = struct {
  type: []const u8,
  model_id: ent.EntityID = 0,
  child_ids: std.AutoHashMap(ent.EntityID, usize),
  hidden: bool = false,
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    type: ?ecs.FieldFilter([]const u8) = null,
    model_id: ?ecs.FieldFilter(ent.EntityID) = null,
    hidden: ?ecs.FieldFilter(bool) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.type) |cond|
      if (!ecs.matchField([]const u8, self.type, cond))
        return false;

    if (f.model_id) |cond|
      if (!ecs.matchField(ent.EntityID, self.model_id, cond))
        return false;

    if (f.hidden) |cond|
      if (!ecs.matchField(bool, self.hidden, cond))
        return false;

    return true;
  }

  pub const Sort = enum {
    type_asc,
    type_desc,
    model_id_asc,
    model_id_desc,
  };

  pub fn compare(a: Data, b: Data, sort: []const Sort) std.math.Order {
    for (sort) |field| {
      const order = switch (field) {
        .type_asc => std.mem.order(u8, a.type, b.type),
        .type_desc => std.mem.order(u8, b.type, a.type),
        .model_id_asc => std.math.order(a.model_id, b.model_id),
        .model_id_desc => std.math.order(b.model_id, a.model_id),
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ent.EntityID {
    return world.query(Query, &world.components.spawn, f, sort);
  }
};


// Testing
const tst = std.testing;
const EntityModel = @import("../entity/model.zig");
const EntitySpawn = @import("../entity/spawn.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  _ = EntityModel.init(world.entity("test cube"), .{.type = "cube"});
  const entity = EntitySpawn.init(world.entity("test1"), .{.model = "test cube", .type = "cube"});
  _ = EntityModel.init(world.entity("test sphere"), .{.type = "sphere"});
  _ = EntitySpawn.init(world.entity("test2"), .{.model = "test sphere", .type = "sphere"});

  // When
  const result = Query.exec(&world, .{ .type = .{ .eq = "cube" }}, &.{.type_asc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity.id, result[0]);
}
