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
    var count: usize = 0;
    var enabled_buffer: [rl.MAX_LIGHTS]i32 = undefined;
    var type_buffer: [rl.MAX_LIGHTS]i32 = undefined;

    var position_buffer: [rl.MAX_LIGHTS]rl.Vector3 = undefined;
    var target_buffer: [rl.MAX_LIGHTS]rl.Vector3 = undefined;
    var color_buffer: [rl.MAX_LIGHTS]rl.Vector4 = undefined;

    var it = self.world.components.shader.iterator();
    while (it.next()) |entry| {
      const shader = entry.value_ptr.*;

      count = 0;
      var it2 = self.world.components.light.iterator();
      while (it2.next()) |entry2| {
        if (!entry2.value_ptr.*.active) continue;

        if (count >= rl.MAX_LIGHTS)
          @panic("Too many lights active on shader");

        const id = entry2.key_ptr.*;
        const light = entry2.value_ptr.*;

        const position = self.world.components.position.get(id) orelse unreachable; // Defined in light component
        const color = self.world.components.color.get(id) orelse unreachable;

        enabled_buffer[count] = 1;
        type_buffer[count] = light.type.raylibType();

        position_buffer[count] = rl.Vector3{ .x = position.x, .y = position.y, .z = position.z };
        target_buffer[count] = rl.Vector3{ .x = light.target.x, .y = light.target.y, .z = light.target.z };
        color_buffer[count] = rl.Vector4{ .x = (@as(f32, @floatFromInt(color.r)) / 255.0), .y = (@as(f32, @floatFromInt(color.g)) / 255.0), .z = (@as(f32, @floatFromInt(color.b)) / 255.0), .w = (@as(f32, @floatFromInt(color.a)) / 255.0) };

        count += 1;
      }

      rl.SetShaderValue(shader.shader, rl.GetShaderLocation(shader.shader, "lightCount"), &count, rl.SHADER_UNIFORM_INT);
      rl.SetShaderValue(shader.shader, rl.GetShaderLocation(shader.shader, "lights[0].enabled"), &enabled_buffer, rl.SHADER_UNIFORM_INT);
      rl.SetShaderValue(shader.shader, rl.GetShaderLocation(shader.shader, "lights[0].type"), &type_buffer, rl.SHADER_UNIFORM_INT);

      rl.SetShaderValue(shader.shader, rl.GetShaderLocation(shader.shader, "lights[0].position"), &position_buffer, rl.SHADER_UNIFORM_VEC3);
      rl.SetShaderValue(shader.shader, rl.GetShaderLocation(shader.shader, "lights[0].target"), &target_buffer, rl.SHADER_UNIFORM_VEC3);
      rl.SetShaderValue(shader.shader, rl.GetShaderLocation(shader.shader, "lights[0].color"), &color_buffer, rl.SHADER_UNIFORM_VEC4);
    }
  }
};


// Testing
const tst = std.testing;
const SystemCamera = @import("camera.zig");
const SystemShader = @import("shader.zig");
const SystemRenderModel = @import("render/model.zig");

test "System should update light" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);
  var system_camera = SystemCamera.System.init(&world);
  var system_shader = SystemShader.System.init(&world);
  var system_model = SystemRenderModel.System.init(&world);

  _ = world.entity("camera").camera(.{});
  _ = world.entity("shader").shader(.{});
  _ = world.entity("test").light(.{.type = .Point}).color(128, 200, 128, 128);
  _ = world.entity("material").material(.{.shader = "shader"});
  _ = world.entity("cube").model(.{.type = "cube", .material = "material"});

  // When
  system_camera.update();
  system_shader.update();
  system.update();

  rl.BeginDrawing();
  rl.ClearBackground(rl.BLACK); // Wipe previous test data
  system_camera.start();
  system_model.render();
  system_camera.stop();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.light");
}
