const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = ecs.raylib;

pub const Component = struct {
  material: rl.Material,
  shader_id: ecs.EntityID = 0,

  pub fn deinit(self: *Component) void{
    self.material.shader = rl.Shader{}; // Unlink shader
    rl.UnloadMaterial(self.material);
  }
};

const Material = struct {
  shader: []const u8 = "",
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    shader_id: ?ecs.FieldFilter(ecs.EntityID) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.shader_id) |cond|
      if (!ecs.matchField(ecs.EntityID, self.shader_id, cond))
        return false;

    return true;
  }

  pub const Sort = enum {noyetimplemented};

  pub fn exec(world: *ecs.World, f: Filter) []ecs.EntityID {
    return world.query(Query, &world.components.material, f, &.{});
  }
};


// Testing
const tst = std.testing;
const EntityMaterial = @import("../entity/material.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const shader1 = world.entity("test shader 1").shader(.{});
  _ = world.entity("test shader 2").shader(.{});

  const entity1 = EntityMaterial.init(world.entity("test1"), .{.shader = "test shader 1"});
  _ = EntityMaterial.init(world.entity("test2"), .{.shader = "test shader 2"});

  // When
  const result = Query.exec(&world, .{ .shader_id = .{ .eq = shader1.id }});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity1.id, result[0]);
}
