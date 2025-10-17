const std = @import("std");
const ecs = @import("../../ecs.zig");

pub const Component = packed struct {
  position: bool = false,
  rotation: bool = false,
  scale: bool = false,
  color: bool = false,

  model: bool = false,
  material: bool = false,
  text: bool = false,
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    position: ?ecs.FieldFilter(bool) = null,
    rotation: ?ecs.FieldFilter(bool) = null,
    scale: ?ecs.FieldFilter(bool) = null,
    color: ?ecs.FieldFilter(bool) = null,

    model: ?ecs.FieldFilter(bool) = null,
    material: ?ecs.FieldFilter(bool) = null,
    text: ?ecs.FieldFilter(bool) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.position) |cond|
      if (!ecs.matchField(bool, self.position, cond))
        return false;
    if (f.rotation) |cond|
      if (!ecs.matchField(bool, self.rotation, cond))
        return false;
    if (f.scale) |cond|
      if (!ecs.matchField(bool, self.scale, cond))
        return false;
    if (f.color) |cond|
      if (!ecs.matchField(bool, self.color, cond))
        return false;

    if (f.model) |cond|
      if (!ecs.matchField(bool, self.model, cond))
        return false;
    if (f.material) |cond|
      if (!ecs.matchField(bool, self.material, cond))
        return false;
    if (f.text) |cond|
      if (!ecs.matchField(bool, self.text, cond))
        return false;

    return true;
  }

  pub const Sort = enum {noyetimplemented};

  pub fn exec(world: *ecs.World, f: Filter) []ecs.EntityID {
    return world.query(Query, &world.components.dirty, f, &.{});
  }
};


// Testing
const tst = std.testing;
const EntityDirty = @import("entity.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  const entity1 = EntityDirty.set(world.entity("test1"), &.{.position, .scale});
  _ = EntityDirty.set(world.entity("test2"), &.{.rotation, .scale});

  // When
  const result = Query.exec(&world, .{ .position = .{ .eq = true } });
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
