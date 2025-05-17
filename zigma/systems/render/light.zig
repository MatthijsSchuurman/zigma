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
    const shader_entity = self.world.entity("shader"); // Use default for now
    const shader = self.world.components.shader.get(shader_entity.id) orelse unreachable;

    var count: usize = 0;
    var enabled_buffer: [rl.MAX_LIGHTS]i32 = undefined;
    var type_buffer: [rl.MAX_LIGHTS]i32 = undefined;

    var position_buffer: [rl.MAX_LIGHTS]rl.Vector3 = undefined;
    var target_buffer: [rl.MAX_LIGHTS]rl.Vector3 = undefined;
    var color_buffer: [rl.MAX_LIGHTS]rl.Vector4 = undefined;

    var it = self.world.components.light.iterator();
    while (it.next()) |entry| {
      if (!entry.value_ptr.*.active) continue;
      if (count >= rl.MAX_LIGHTS) break; // Shouldn't happen but lets be sure

      const id = entry.key_ptr.*;
      const light = entry.value_ptr.*;

      const position = self.world.components.position.get(id) orelse unreachable; // Defined in light component
      const color = self.world.components.color.get(id) orelse unreachable;

      enabled_buffer[count] = if (light.active) 1 else 0;
      type_buffer[count] = light.type.raylibType();

      position_buffer[count] = rl.Vector3{ .x = position.x, .y = position.y, .z = position.z };
      target_buffer[count] = rl.Vector3{ .x = light.target.x, .y = light.target.y, .z = light.target.z };
      color_buffer[count] = rl.Vector4{ .x = (@as(f32, @floatFromInt(color.r)) / 255.0), .y = (@as(f32, @floatFromInt(color.g)) / 255.0), .z = (@as(f32, @floatFromInt(color.b)) / 255.0), .w = (@as(f32, @floatFromInt(color.a)) / 255.0) };

      std.debug.print("Light shader id: {}\n", .{shader.lighting.id});
      std.debug.print("Light {}: enabled: {}, type: {}, position: ({}, {}, {}), target: ({}, {}, {}), color: ({}, {}, {}, {})\n",.{
        count,
        enabled_buffer[count],
        type_buffer[count],
        position_buffer[count].x, position_buffer[count].y, position_buffer[count].z,
        target_buffer[count].x, target_buffer[count].y, target_buffer[count].z,
        color_buffer[count].x, color_buffer[count].y, color_buffer[count].z, color_buffer[count].w
      });
      count += 1;
    }

    rl.SetShaderValue(shader.lighting, rl.GetShaderLocation(shader.lighting, "lightCount"), &count, rl.SHADER_UNIFORM_INT);
    rl.SetShaderValue(shader.lighting, rl.GetShaderLocation(shader.lighting, "lights[0].enabled"), &enabled_buffer, rl.SHADER_UNIFORM_INT);
    rl.SetShaderValue(shader.lighting, rl.GetShaderLocation(shader.lighting, "lights[0].type"), &type_buffer, rl.SHADER_UNIFORM_INT);

    rl.SetShaderValue(shader.lighting, rl.GetShaderLocation(shader.lighting, "lights[0].position"), &position_buffer, rl.SHADER_UNIFORM_VEC3);
    rl.SetShaderValue(shader.lighting, rl.GetShaderLocation(shader.lighting, "lights[0].target"), &target_buffer, rl.SHADER_UNIFORM_VEC3);
    rl.SetShaderValue(shader.lighting, rl.GetShaderLocation(shader.lighting, "lights[0].color"), &color_buffer, rl.SHADER_UNIFORM_VEC4);
  }
};


// Testing
const tst = std.testing;
const model_system = @import("model.zig");

test "System should render light" {
  // Given
  rl.InitWindow(320, 200, "test");
  defer rl.CloseWindow();

  var world = ecs.World.init(tst.allocator);
  world.initSystems();
  defer world.deinit();

  var system = System.init(&world);
  var system2 = model_system.System.init(&world);

  _ = world.entity("camera").camera(.{});
  _ = world.entity("shader").shader(.{});
  _ = world.entity("test").light(.{.type = .point});
  _ = world.entity("test2").model(.{.type = "cube"});

  // When
  rl.BeginDrawing();
  world.systems.camera.start();
  system.render();
  system2.render();
  world.systems.camera.stop();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.render.light");
}
