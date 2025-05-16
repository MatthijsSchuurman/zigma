const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = @cImport({
  @cInclude("raylib.h");
  @cInclude("raymath.h");
});

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn render(self: *System) void {
    const shader_entity = self.world.entity("shader");
    const shader = self.world.components.shader.get(shader_entity.id) orelse unreachable;
    const matNormal_location = rl.GetShaderLocation(shader.lighting, "matNormal");

    var it = self.world.components.model.iterator();
    while (it.next()) |entry| {
      const id = entry.key_ptr.*;
      const model = entry.value_ptr.*;

      const position = self.world.components.position.get(id) orelse unreachable; // Defined in model component
      const rotation = self.world.components.rotation.get(id) orelse unreachable;
      const scale = self.world.components.scale.get(id) orelse unreachable;
      const color = self.world.components.color.get(id) orelse unreachable;

      const model_matrix = rl.MatrixMultiply(
        rl.MatrixRotateXYZ(rl.Vector3{ .x = rotation.x, .y = rotation.y, .z = rotation.z }),
        rl.MatrixTranslate(position.x, position.y, position.z));

      const normal_matrix = rl.MatrixTranspose(rl.MatrixInvert(model_matrix));

      rl.BeginShaderMode(shader.lighting);
      rl.SetShaderValueMatrix(shader.lighting, matNormal_location, normal_matrix);

      rl.DrawModelEx(
        model.model,
        rl.Vector3{ .x = position.x, .y = position.y, .z = position.z },
        rl.Vector3{ .x = rotation.x, .y = rotation.y, .z = rotation.z }, // rotation axis
        0.0, // rotation angle
        rl.Vector3{ .x = scale.x, .y = scale.y, .z = scale.z },
        rl.Color{ .r = color.r, .g = color.g, .b = color.b, .a = color.a },
      );

      rl.EndShaderMode();
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
