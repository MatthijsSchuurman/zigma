const std = @import("std");
const ecs = @import("../../ecs.zig");

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn clean(self: *System) void {
    self.world.components.dirty.clearRetainingCapacity();
  }
};


// Testing
const tst = std.testing;

test "System should clean dirty things" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  _ = world.entity("test").dirty(&.{.position});

  var system = System.init(&world);

  // When
  system.clean();

  // Then
  try tst.expectEqual(0, world.components.dirty.count());
}
