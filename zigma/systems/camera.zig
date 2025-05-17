const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = ecs.raylib;

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn start(self: *System) void {
    const shader_entity = self.world.entity("shader"); // Use default for now
    const shader = self.world.components.shader.get(shader_entity.id) orelse unreachable;

    var it = self.world.components.camera.iterator();
    while (it.next()) |entry| {
      if (!entry.value_ptr.*.active) continue;

      const position = self.world.components.position.get(entry.key_ptr.*) orelse unreachable; // Defined in camera component
      const rotation = self.world.components.rotation.get(entry.key_ptr.*) orelse unreachable;

      const camera = rl.Camera3D{
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
      };

      std.debug.print("Camera shader id: {}\n", .{shader.lighting.id});
      const asdf = rl.Vector4{.x = 0.3, .y = 0.3, .z = 0.3, .w = 1};
      rl.SetShaderValue(shader.lighting, rl.GetShaderLocation(shader.lighting, "ambient"), &asdf, rl.SHADER_UNIFORM_VEC4); //DO ONCE

      rl.SetShaderValue(shader.lighting, rl.GetShaderLocation(shader.lighting, "viewPos"), &camera.position, rl.SHADER_UNIFORM_VEC3);

      rl.BeginMode3D(camera);
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

  _ = world.entity("shader").shader(.{});

  // When
  rl.BeginDrawing();
  system.start();
  system.stop();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.camera");
}
