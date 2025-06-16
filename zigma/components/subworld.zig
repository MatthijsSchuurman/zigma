const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

pub const Component = struct {
  world: *ecs.World,
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    world: ?ecs.FieldFilter(*ecs.World) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.world) |cond|
      if (!ecs.matchField(*ecs.World, self.world, cond))
        return false;

    return true;
  }

  pub const Sort = enum {noyetimplemented};

  pub fn exec(world: *ecs.World, f: Filter) []ent.EntityID {
    return world.query(Query, &world.components.subworld, f, &.{});
  }
};


// Testing
const tst = std.testing;
const EntitySubWorld = @import("../entity/subworld.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);
  var world2 = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world2);

  const entity1 = EntitySubWorld.init(world.entity("test1"), &world);
  _ = EntitySubWorld.init(world.entity("test2"), &world2);

  // When
  const result = Query.exec(&world, .{ .world = .{ .eq = &world } });
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
