const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = @cImport(@cInclude("raylib.h"));

const light_component = @import("../../components/light.zig");

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
    var position_buffer: [light_component.MAX_LIGHTS]rl.Vector4 = undefined;
    var color_buffer: [light_component.MAX_LIGHTS]rl.Vector4 = undefined;

    var it = self.world.components.light.iterator();
    while (it.next()) |entry| {
      if (count >= light_component.MAX_LIGHTS) break; // Shouldn't happen but lets be sure

      const id = entry.key_ptr.*;
      const light = entry.value_ptr.*;

      const position = self.world.components.position.get(id) orelse unreachable; // Defined in light component
      const color = self.world.components.color.get(id) orelse unreachable;

      position_buffer[count] = rl.Vector4{ .x = position.x, .y = position.y, .z = position.z, .w = light.radius };
      color_buffer[count] = rl.Vector4{ .x = (@as(f32, @floatFromInt(color.r)) / 255.0), .y = (@as(f32, @floatFromInt(color.g)) / 255.0), .z = (@as(f32, @floatFromInt(color.b)) / 255.0), .w = (@as(f32, @floatFromInt(color.a)) / 255.0) };

      count += 1;
    }

    rl.SetShaderValue(shader.lighting, rl.GetShaderLocation(shader.lighting, "lights[0].position"), &position_buffer, rl.SHADER_UNIFORM_VEC4);
    rl.SetShaderValue(shader.lighting, rl.GetShaderLocation(shader.lighting, "lights[0].color"), &color_buffer, rl.SHADER_UNIFORM_VEC4);
    rl.SetShaderValue(shader.lighting, rl.GetShaderLocation(shader.lighting, "lightCount"), &count, rl.SHADER_UNIFORM_INT);
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
