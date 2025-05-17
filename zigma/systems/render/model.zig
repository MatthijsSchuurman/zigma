const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = ecs.raylib;

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn render(self: *System) void {
    var it = self.world.components.model.iterator();
    while (it.next()) |entry| {
      const id = entry.key_ptr.*;
      const model = entry.value_ptr.*;

      const position = self.world.components.position.get(id) orelse unreachable; // Defined in model component
      const rotation = self.world.components.rotation.get(id) orelse unreachable;
      const scale = self.world.components.scale.get(id) orelse unreachable;
      const color = self.world.components.color.get(id) orelse unreachable;

      rl.DrawModelEx(
        model.model,
        rl.Vector3{ .x = position.x, .y = position.y, .z = position.z },
        rl.Vector3{ .x = rotation.x, .y = rotation.y, .z = rotation.z }, // rotation axis
        0.0, // rotation angle
        rl.Vector3{ .x = scale.x, .y = scale.y, .z = scale.z },
        rl.Color{ .r = color.r, .g = color.g, .b = color.b, .a = color.a },
      );
    }
  }
};


// Testing
const tst = std.testing;

test "System should render model" {
  // Given
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

  var world = ecs.World.init(tst.allocator);
  world.initSystems();
  defer world.deinit();

  var system = System.init(&world);

  _ = world.entity("camera").camera(.{});
  _ = world.entity("shader").shader(.{});
  _ = world.entity("test").model(.{.type = "cube"});

  // When
  rl.BeginDrawing();
  world.systems.camera.start();
  system.render();
  world.systems.camera.stop();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.render.model");
}
