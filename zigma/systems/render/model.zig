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


  pub fn transform(position: rl.Vector3, rotation: rl.Vector3, scale: rl.Vector3) rl.Matrix {
    const rad = std.math.pi * 2;
    const R = rl.MatrixRotateXYZ(rl.Vector3{
      .x = rotation.x * rad,
      .y = rotation.y * rad,
      .z = rotation.z * rad
    });
    const S = rl.MatrixScale(scale.x, scale.y, scale.z);
    const T = rl.MatrixTranslate(position.x, position.y, position.z);
    return rl.MatrixMultiply(rl.MatrixMultiply(R, S), T);
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
      self.renderModel(id);

    // Render transparent models
    rl.rlDisableDepthMask();
    rl.BeginBlendMode(rl.BLEND_ALPHA);
    for (ids.transparent) |id| {
      var shader: ?rl.Shader = null;
      var loc_color_diffuse: c_int = 0;

      if (self.world.components.model.getPtr(id)) |model| {
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
        }
      }

      self.renderModel(id);
    }

    rl.EndShaderMode();
    rl.EndBlendMode();
    rl.rlEnableDepthMask();
  }

  fn renderModel(self: *System, id: ent.EntityID) void {
    var model = self.world.components.model.getPtr(id) orelse unreachable;
    const color = self.world.components.color.get(id) orelse unreachable;

    if (model.transforms) |transforms| { // Multi render
      for (transforms.items) |t| {
        model.model.transform = t;
        rl.DrawModel(
          model.model,
          rl.Vector3Zero(),
          1.0,
          color,
        );
      }
    } else { // Single render
      if (self.world.components.dirty.get(id)) |dirty| {
        if (dirty.position or dirty.rotation or dirty.scale) {
          model.model.transform = transform(
            self.world.components.position.get(id) orelse unreachable, // Defined in model entity
            self.world.components.rotation.get(id) orelse unreachable,
            self.world.components.scale.get(id) orelse unreachable,
          );
        }
      }

      rl.DrawModel(
        model.model,
        rl.Vector3Zero(),
        1.0,
        color,
      );
    }
  }
};


// Testing
const tst = std.testing;
const SystemCamera = @import("../camera.zig");

test "Should should transform" {
  // Given

  // When
  const result = System.transform(
    rl.Vector3{.x = 1, .y = 2, .z = 3},
    rl.Vector3{.x = 0, .y = 0, .z = 0},
    rl.Vector3{.x = 1, .y = 1, .z = 1},
  );

  // Then
  try tst.expectEqual(rl.Matrix{
    .m0 = 1, .m1 = 0, .m2 = 0, .m3 = 0,
    .m4 = 0, .m5 = 1, .m6 = 0, .m7 = 0,
    .m8 = 0, .m9 = 0, .m10 = 1, .m11 = 0,
    .m12 = 1, .m13 = 2, .m14 = 3, .m15 = 1,
  }, result);
}

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
