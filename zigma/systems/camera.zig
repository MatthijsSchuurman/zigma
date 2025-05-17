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

  pub fn update(self: *System) void {
    var it = self.world.components.camera.iterator();
    while (it.next()) |entry| {
      if (!entry.value_ptr.*.active) continue;

      const position = self.world.components.position.get(entry.key_ptr.*) orelse unreachable; // Defined in camera component
      const camera_position = rl.Vector3{
        .x = position.x,
        .y = position.y,
        .z = position.z,
      };

      var it2 = self.world.components.shader.iterator();
      while (it2.next()) |entry2| {
        const shader = entry2.value_ptr.*;

        rl.SetShaderValue(shader.shader, rl.GetShaderLocation(shader.shader, "viewPos"), &camera_position, rl.SHADER_UNIFORM_VEC3);
      }

      break; // Only one camera for now
    }
  }

  pub fn start(self: *System) void {
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

      rl.BeginMode3D(camera);

      break; // Only one camera for now
    }
  }

  pub fn stop(self: *System) void {
    var it = self.world.components.camera.iterator();
    while (it.next()) |entry| {
      if (!entry.value_ptr.*.active) continue;

      rl.EndMode3D();

      break; // Only one camera for now
    }
  }
};


// Testing
const tst = std.testing;
const SystemRenderModel = @import("render/model.zig");

test "System should update camera" {
  // Given
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);

  // When
  system.update();
}

test "System should start / stop camera" {
  // Given
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);
  var system_model = SystemRenderModel.System.init(&world);

  _ = world.entity("test").camera(.{});
  _ = world.entity("cube").model(.{.type = "cube"});

  // When
  rl.BeginDrawing();
  system.start();
  system_model.render();
  system.stop();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.camera");
}
