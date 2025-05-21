const std = @import("std");
const ecs = @import("../ecs.zig");
const ent = @import("../entity.zig");
const rl = ecs.raylib;

pub const Component = rl.Color;

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    r: ?ecs.FieldFilter(u8) = null,
    g: ?ecs.FieldFilter(u8) = null,
    b: ?ecs.FieldFilter(u8) = null,
    a: ?ecs.FieldFilter(u8) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.r) |cond|
      if (!ecs.matchField(u8, self.r, cond))
        return false;

    if (f.g) |cond|
      if (!ecs.matchField(u8, self.g, cond))
        return false;

    if (f.b) |cond|
      if (!ecs.matchField(u8, self.b, cond))
        return false;

    if (f.a) |cond|
      if (!ecs.matchField(u8, self.a, cond))
        return false;

    return true;
  }

  pub const Sort = enum {noyetimplemented};

  pub fn exec(world: *ecs.World, f: Filter) []ent.EntityID {
    return world.query(Query, &world.components.color, f, &.{});
  }
};


// Testing
const tst = std.testing;
const EntityColor= @import("../entity/color.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity1 = EntityColor.set(world.entity("test1"), 1, 2, 3, 4);
  _ = EntityColor.set(world.entity("test2"), 5, 6, 7, 8);

  // When
  const result = Query.exec(&world, .{ .r = .{ .eq = 1 } });
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(result.len, 1);
  try tst.expectEqual(result[0], entity1.id);
}
