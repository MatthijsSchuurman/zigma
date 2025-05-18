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
    var it = self.world.components.shader.iterator();
    while (it.next()) |entry| {
      const id = entry.key_ptr.*;
      const shader = entry.value_ptr.*;

      const color = self.world.components.color.get(id) orelse unreachable; // Defined in shader component

      const ambient_color = rl.Vector4{
        .x = (@as(f32, @floatFromInt(color.r)) / 255.0),
        .y = (@as(f32, @floatFromInt(color.g)) / 255.0),
        .z = (@as(f32, @floatFromInt(color.b)) / 255.0),
        .w = (@as(f32, @floatFromInt(color.a)) / 255.0)
      };

      rl.SetShaderValue(shader.shader, rl.GetShaderLocation(shader.shader, "ambient"), &ambient_color, rl.SHADER_UNIFORM_VEC4);
    }
  }
};


// Testing
const tst = std.testing;
const SystemCamera = @import("camera.zig");
const SystemLight= @import("light.zig");
const SystemRenderModel = @import("render/model.zig");

test "System should update shader" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);
  var system_camera = SystemCamera.System.init(&world);
  var system_light= SystemLight.System.init(&world);
  var system_model = SystemRenderModel.System.init(&world);
  defer system_model.deinit();

  _ = world.entity("camera").camera(.{});
  _ = world.entity("shader").shader(.{});
  _ = world.entity("test").light(.{.type = .Point});
  _ = world.entity("material").material(.{.shader = "shader"});
  _ = world.entity("cube").model(.{.type = "cube", .material = "material"});

  // When
  system_camera.update();
  system.update();
  system_light.update();

  rl.BeginDrawing();
  rl.ClearBackground(rl.BLACK); // Wipe previous test data
  system_camera.start();
  system_model.render();
  system_camera.stop();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.shader");
}
