const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

pub const Component = struct {
  hidden: bool,
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    hidden: ?ecs.FieldFilter(bool) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.hidden) |cond|
      if (!ecs.matchField(bool, self.hidden, cond))
        return false;

    return true;
  }

  pub const Sort = enum {noyetimplemented};

  pub fn exec(world: *ecs.World, f: Filter) []ent.EntityID {
    return world.query(Query, &world.components.hide, f, &.{});
  }
};


// Testing
const tst = std.testing;
const EntityHide = @import("../entity/hide.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity1 = EntityHide.hide(world.entity("test1"));
  _ = EntityHide.unhide(world.entity("test2"));

  // When
  const result = Query.exec(&world, .{ .hidden = .{ .eq = true } });
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
