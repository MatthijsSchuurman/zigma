const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = @cImport(@cInclude("raylib.h"));

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn setup(self: *System) void {
    var it = self.world.components.camera.iterator();

    while (it.next()) |entry| {
      if (!entry.value_ptr.*.active) continue;

      const position = self.world.components.position.get(entry.key_ptr.*) orelse unreachable;
      const rotation = self.world.components.rotation.get(entry.key_ptr.*) orelse unreachable;

      rl.BeginMode3D(rl.Camera3D{
        .target = rl.Vector3{
          .x = entry.value_ptr.*.target.x,
          .y = entry.value_ptr.*.target.y,
          .z = entry.value_ptr.*.target.z,
        },
        .position = rl.Vector3{
          .x = position.x,
          .y = position.y,
          .z = position.z,
        },
        .up = rl.Vector3{
          .x = rotation.x,
          .y = rotation.y,
          .z = rotation.z,
        },
        .fovy = entry.value_ptr.*.fovy,
        .projection = rl.CAMERA_PERSPECTIVE,
      });

      break;
    }
  }
};


// Testing
const tst = std.testing;
const zigma = @import("../ma.zig");

test "System should setup camera" {
  // Given
  zigma.init(.{.title = "test", .width = 320, .height = 200 });
  rl.SetTargetFPS(10);
  defer zigma.deinit();

  const world = zigma.create();
  defer zigma.destroy(world);

  var system = System.init(world);

  // When
  rl.BeginDrawing();
  system.setup();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.camera");
}
