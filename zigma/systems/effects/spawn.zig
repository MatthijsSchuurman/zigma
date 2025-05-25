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

  pub fn update(self: *System) void {
    var it = self.world.components.spawn.iterator();
    while(it.next()) |entry| {
      const id = entry.key_ptr.*;
      const spawn = entry.value_ptr.*;

      if (self.world.components.dirty.get(id)) |dirty| { // Spawn dirty
        if (dirty.rotation) {
          const rotation = self.world.components.rotation.get(id) orelse unreachable;

          var it2 = spawn.child_ids.iterator();
          while (it2.next()) |entry2| {
            const child_id = entry2.key_ptr.*;
            _ = self.world.entityWrap(child_id).rotation(rotation.x, rotation.y, rotation.z);
          }
        }

        if (dirty.scale) {
          const scale = self.world.components.scale.get(id) orelse unreachable;

          var it2 = spawn.child_ids.iterator();
          while (it2.next()) |entry2| {
            const child_id = entry2.key_ptr.*;
            _ = self.world.entityWrap(child_id).scale(scale.x, scale.y, scale.z);
          }
        }

        if (dirty.color) {
          const color = self.world.components.color.get(id) orelse unreachable;

          var it2 = spawn.child_ids.iterator();
          while (it2.next()) |entry2| {
            const child_id = entry2.key_ptr.*;
            _ = self.world.entityWrap(child_id).color(color.r, color.g, color.b, color.a);
          }
        }
      }

      if (self.world.components.dirty.get(spawn.model_id)) |dirty| { // Model dirty
        if (dirty.position or dirty.rotation or dirty.scale) {
          _ = self.world.entityWrap(spawn.model_id).model_transform( // Pre transform model, redone by model system
            self.world.components.position.get(spawn.model_id) orelse unreachable,
            self.world.components.rotation.get(spawn.model_id) orelse unreachable,
            self.world.components.scale.get(spawn.model_id) orelse unreachable,
          );

          const model = self.world.components.model.get(spawn.model_id) orelse unreachable;
          const mesh = model.model.meshes[0];

          var it2 = spawn.child_ids.iterator();
          while (it2.next()) |entry2| {
            const child_id = entry2.key_ptr.*;
            const vi = entry2.value_ptr.*;
            const base = vi * 3;

            const position = rl.Vector3{
              .x = mesh.vertices[base + 0],
              .y = mesh.vertices[base + 1],
              .z = mesh.vertices[base + 2],
            };

            const transformed = rl.Vector3Transform(position, model.model.transform);
            _ = self.world.entityWrap(child_id).position(transformed.x, transformed.y, transformed.z);
          }
        }
      }
    }
  }
};


// Testing
const tst = std.testing;

test "System should update position" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  _ = world.entity("cube").model(.{.type = "cube"});
  const entity = world.entity("test")
  .spawn(.{.model = "cube", .type = "torus"})
  .color(128, 128, 128, 255);

  var system = System.init(&world);

  // When
  system.update();

  // Then
  if (entity.world.components.position.get(3)) |position|
    try tst.expectEqual(ecs.Components.Position.Component{.x = -0.5, .y = -0.5, .z = 0.5}, position)
   else
    return error.TestExpectedPosition;

  if (entity.world.components.color.get(4)) |color|
    try tst.expectEqual(ecs.Components.Color.Component{.r = 128, .g = 128, .b = 128, .a = 255}, color)
   else
    return error.TestExpectedColor;

  if (entity.world.components.dirty.get(5)) |dirty|
    try tst.expectEqual(true, dirty.position)
   else
    return error.TestExpectedDirty;
}
