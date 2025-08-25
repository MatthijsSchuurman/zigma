const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn active(self: *System) ent.EntityID {
    var it = self.world.components.camera.iterator();
    while (it.next()) |entry|
      if (entry.value_ptr.*.active) return entry.key_ptr.*;

    return 0;
  }

  pub fn update(self: *System) void {
    const camera_id = self.active();
    if (camera_id == 0) return;

    const position = self.world.components.position.getPtr(camera_id) orelse unreachable; // Defined in camera entity

    var it2 = self.world.components.shader.iterator();
    while (it2.next()) |entry2| {
      const shader = entry2.value_ptr.*;

      rl.SetShaderValue(shader.shader, rl.GetShaderLocation(shader.shader, "viewPos"), position, rl.SHADER_UNIFORM_VEC3);
    }
  }

  pub fn start(self: *System) void {
    const camera_id = self.active();
    if (camera_id == 0) return;

    if (self.world.components.camera.getPtr(camera_id)) |entry| {
      const position = self.world.components.position.getPtr(camera_id) orelse unreachable; // Defined in camera entity
      const rotation = self.world.components.rotation.getPtr(camera_id) orelse unreachable;

      const camera = rl.Camera3D{
        .target = entry.target,
        .position = position.*,
        .up = rotation.*,
        .fovy = entry.fovy,
        .projection = rl.CAMERA_PERSPECTIVE,
      };

      rl.BeginMode3D(camera);
    }
  }

  pub fn stop(self: *System) void {
    const camera_id = self.active();
    if (camera_id == 0) return;

    rl.EndMode3D();
  }
};


// Testing
const tst = std.testing;

test "System should update camera" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);

  // When
  system.update();
}

test "System should start / stop camera" {
  // Given
  const ModuleModel = @import("../model/module.zig").Module;

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);
  world.systems.camera = system; // Needed by model system
  var system_model = ModuleModel.Systems.Model.System.init(&world);
  defer system_model.deinit();

  _ = world.entity("test").camera(.{});
  _ = world.entity("cube").model(.{.type = "cube"});

  // When
  rl.BeginDrawing();
  rl.ClearBackground(rl.BLACK); // Wipe previous test data
  system.start();
  system_model.render();
  system.stop();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.camera");
}
