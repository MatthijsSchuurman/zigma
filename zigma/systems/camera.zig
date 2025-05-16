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

  pub fn start(self: *System) void {
    var it = self.world.components.camera.iterator();

    while (it.next()) |entry| {
      if (!entry.value_ptr.*.active) continue;

      const position = self.world.components.position.get(entry.key_ptr.*) orelse unreachable; // Defined in camera component
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

  pub fn stop(self: *System) void {
    var it = self.world.components.camera.iterator();

    while (it.next()) |entry| {
      if (!entry.value_ptr.*.active) continue;

      rl.EndMode3D();
      break;
    }
  }
};


// Testing
const tst = std.testing;

test "System should start / stop camera" {
  // Given
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);

  // When
  rl.BeginDrawing();
  system.start();
  system.stop();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.camera");
}
