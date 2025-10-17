const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = ecs.raylib;

pub const Component = struct {
  source_model_id: ecs.EntityID = 0,
  vertex_indexes: std.ArrayList(usize),
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    source_model_id: ?ecs.FieldFilter(ecs.EntityID) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.source_model_id) |cond|
      if (!ecs.matchField(ecs.EntityID, self.source_model_id, cond))
        return false;

    return true;
  }

  pub const Sort = enum {
    source_model_id_asc,
    source_model_id_desc,
  };

  pub fn compare(a: Data, b: Data, sort: []const Sort) std.math.Order {
    for (sort) |field| {
      const order = switch (field) {
        .source_model_id_asc => std.math.order(a.source_model_id, b.source_model_id),
        .source_model_id_desc => std.math.order(b.source_model_id, a.source_model_id),
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ecs.EntityID {
    return world.query(Query, &world.components.spawn, f, sort);
  }
};


// Testing
const tst = std.testing;

test "Query should filter" {
  // Given
  const ModuleModel = @import("../model/module.zig").Module;
  const EntitySpawn = @import("entity.zig");

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  _ = ModuleModel.Entities.Model.init(world.entity("test cube"), .{.type = "cube"});
  _ = ModuleModel.Entities.Model.init(world.entity("test1"), .{.type = "cube"});
  const entity = EntitySpawn.init(world.entity("test1"), .{.source_model = "test cube"});

  _ = ModuleModel.Entities.Model.init(world.entity("test sphere"), .{.type = "sphere"});
  _ = ModuleModel.Entities.Model.init(world.entity("test2"), .{.type = "sphere"});
  _ = EntitySpawn.init(world.entity("test2"), .{.source_model = "test sphere"});

  // When
  const result = Query.exec(&world, .{ .source_model_id = .{ .eq = 1 }}, &.{.source_model_id_asc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity.id, result[0]);
}
