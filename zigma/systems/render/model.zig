const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

pub const System = struct {
  world: *ecs.World,

  opaques: std.ArrayList(ent.EntityID), // Use preallocated lists for splitByAlpha
  transparent: std.ArrayList(ent.EntityID),

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,

      .opaques = std.ArrayList(ent.EntityID).init(world.allocator),
      .transparent = std.ArrayList(ent.EntityID).init(world.allocator),
    };
  }

  pub fn deinit(self: *System) void {
    self.opaques.deinit();
    self.transparent.deinit();
  }


  const SplitByAlphaIDs = struct {
    opaques: []const ent.EntityID,
    transparent: []const ent.EntityID,
  };
  fn splitByAlpha(self: *System) SplitByAlphaIDs {
    self.opaques.clearRetainingCapacity(); // Clear previous data
    self.transparent.clearRetainingCapacity();

    var it = self.world.components.model.iterator();
    while (it.next()) |model| {
      if (model.value_ptr.hidden) continue;

      if (model.value_ptr.material_id == 0) { // No material (no shader)
        self.opaques.append(model.key_ptr.*) catch @panic("Failed to store model entity id");
        continue;
      }

      if (self.world.components.material.get(model.value_ptr.material_id)) |material| {
        if (material.shader_id == 0) { // Default shader
          self.opaques.append(model.key_ptr.*) catch @panic("Failed to store model entity id");
          continue;
        }
      }

      if (self.world.components.color.get(model.key_ptr.*)) |color| {
        if (color.a == 255) { // Opaque
          self.opaques.append(model.key_ptr.*) catch @panic("Failed to store model entity id");
          continue;
        }
      } else {
        self.opaques.append(model.key_ptr.*) catch @panic("Failed to store model entity id");
        continue;
      }

      self.transparent.append(model.key_ptr.*) catch @panic("Failed to store model entity id");
    }

    return SplitByAlphaIDs{
      .opaques = self.opaques.items,
      .transparent = self.transparent.items,
    };
  }

  const Comparator = struct {
    world: *ecs.World,
    camera_position: rl.Vector3,

    pub fn lessThan(
        self: *const Comparator,
        a: ent.EntityID,
        b: ent.EntityID,
    ) bool {
        const pa = self.world.components.position.get(a).?;
        const pb = self.world.components.position.get(b).?;
        return rl.Vector3DistanceSqr(pa, self.camera_position)
             > rl.Vector3DistanceSqr(pb, self.camera_position);
    }
  };

  pub fn render(self: *System) void {
    const camera_id = self.world.systems.camera.active();
    if (camera_id == 0) return; // What's even the point...

    const ids = self.splitByAlpha();

    // Determine transparent models order
    const camera_position = self.world.components.position.get(camera_id) orelse unreachable;
    const comparator = Comparator{
      .world = self.world,
      .camera_position = camera_position,
    };
    std.sort.pdq(ent.EntityID, self.transparent.items, &comparator, Comparator.lessThan);

    // Render opaque models
    for (ids.opaques) |id|
      if (self.world.components.model.get(id)) |model|
        self.renderModel(id, model);

    // Render transparent models
    rl.rlDisableDepthMask();
    rl.BeginBlendMode(rl.BLEND_ALPHA);
    for (ids.transparent) |id| {
      var shader: ?rl.Shader = null;
      var loc_color_diffuse: c_int = 0;

      if (self.world.components.model.get(id)) |model| {
        if (self.world.components.material.get(model.material_id)) |material| {
          if (shader == null or shader.?.id != material.material.shader.id) { // Different shader
            if (shader != null) // Unload previous shader
              rl.EndBlendMode();

            // Load new shader
            shader = material.material.shader;
            rl.BeginShaderMode(shader.?);
            loc_color_diffuse = rl.GetShaderLocation(shader.?, "colDiffuse");
          }

          if (self.world.components.color.get(id)) |color|
            rl.SetShaderValue(shader.?, loc_color_diffuse, &color, rl.SHADER_UNIFORM_VEC4);

          self.renderModel(id, model);
        }
      }
    }

    rl.EndShaderMode();
    rl.EndBlendMode();
    rl.rlEnableDepthMask();
  }

  fn renderModel(self: *System, id: ent.EntityID, model: ecs.Components.Model.Component) void {
    const position = self.world.components.position.get(id) orelse unreachable; // Defined in model entity
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
  defer system.deinit();
  var system_camera = SystemCamera.System.init(&world);
  world.systems.camera = system_camera; // Needed by model system

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
