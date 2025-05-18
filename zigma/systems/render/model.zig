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
    var it = self.world.components.model.iterator();

    // Draw models without material
    while (it.next()) |model|
      if (model.value_ptr.material_id == 0)
        self.renderModel(model.key_ptr.*, model.value_ptr.*);

    // Draw models with default shader
    var shaderUsed: ?rl.Shader = null;

    it.index = 0; // Reset iterator
    while (it.next()) |model| { // Find models that use shader
      if (model.value_ptr.material_id > 0) {
        if (self.world.components.material.get(model.value_ptr.material_id)) |material| {
          if (material.shader_id == 0) {
            shaderUsed = material.material.shader;
            break;
          }
        }
      }
    }

    if (shaderUsed) |shader| {
      rl.BeginShaderMode(shader);

      it.index = 0; // Reset iterator
      while (it.next()) |model|
        if (model.value_ptr.material_id > 0)
          if (self.world.components.material.get(model.value_ptr.material_id)) |material|
            if (material.shader_id == 0)
             self.renderModel(model.key_ptr.*, model.value_ptr.*);

      rl.EndShaderMode();
    }

    // Draw models for all defined shaders
    var it2 = self.world.components.shader.iterator();
    while (it2.next()) |shader| {
      const loc_color_diffuse = rl.GetShaderLocation(shader.value_ptr.shader, "colDiffuse");

      rl.rlDisableDepthMask();
      rl.BeginBlendMode(rl.BLEND_ALPHA);
      rl.BeginShaderMode(shader.value_ptr.shader);

      it.index = 0; // Reset iterator
      while (it.next()) |model| {
        if (model.value_ptr.material_id > 0) {
          if (self.world.components.material.get(model.value_ptr.material_id)) |material| {
            if (material.shader_id == shader.key_ptr.*) {
              const color = self.world.components.color.get(model.key_ptr.*) orelse unreachable;
              rl.SetShaderValue(shader.value_ptr.shader, loc_color_diffuse, &color, rl.SHADER_UNIFORM_VEC4);

              self.renderModel(model.key_ptr.*, model.value_ptr.*);
            }
          }
        }
      }

      rl.EndShaderMode();
      rl.EndBlendMode();
      rl.rlEnableDepthMask();
    }
  }

  fn renderModel(self: *System, id: ecs.EntityID, model: ecs.Components.Model.Component) void {
    std.debug.print("Rendering model: {d} {s}\n", .{id, model.type});
    const position = self.world.components.position.get(id) orelse unreachable; // Defined in model component
    const rotation = self.world.components.rotation.get(id) orelse unreachable;
    const scale = self.world.components.scale.get(id) orelse unreachable;
    const color = self.world.components.color.get(id) orelse unreachable;

    rl.DrawModelEx(
      model.model,
      position,
      rotation, // rotation axis
      0.0, // rotation angle
      scale,
      color,
    );
  }
};


// Testing
const tst = std.testing;
const SystemCamera = @import("../camera.zig");

test "System should render model" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);
  var system_camera = SystemCamera.System.init(&world);

  _ = world.entity("camera").camera(.{});
  _ = world.entity("test").model(.{.type = "cube"});

  // When
  rl.BeginDrawing();
  rl.ClearBackground(rl.BLACK); // Wipe previous test data
  system_camera.start();
  system.render();
  system_camera.stop();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.render.model");
}
