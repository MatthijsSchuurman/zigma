const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const EntityModel = @import("../../entity/model.zig");
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

      if (self.world.components.dirty.getPtr(spawn.source_model_id)) |dirty| { // Spawn dirty
        if (dirty.position or dirty.rotation or dirty.scale) {
          _ = self.world.entityWrap(spawn.source_model_id).model_transform( // Pre transform model, redone by model system
            self.world.components.position.get(spawn.source_model_id) orelse unreachable,
            self.world.components.rotation.get(spawn.source_model_id) orelse unreachable,
            self.world.components.scale.get(spawn.source_model_id) orelse unreachable,
          );

          const source_model = self.world.components.model.getPtr(spawn.source_model_id) orelse unreachable;
          const source_mesh = source_model.model.meshes[0];

          const model = self.world.components.model.getPtr(id) orelse unreachable;
          const rotation = self.world.components.rotation.get(id) orelse unreachable;
          const scale = self.world.components.scale.get(id) orelse unreachable;

          for (0..spawn.vertex_indexes.items.len) |i| {
            const base = spawn.vertex_indexes.items[i] * 3;
            var position = rl.Vector3{
              .x = source_mesh.vertices[base + 0],
              .y = source_mesh.vertices[base + 1],
              .z = source_mesh.vertices[base + 2],
            };
            position = rl.Vector3Transform(position, source_model.model.transform);

            model.transforms.?.items[i] = EntityModel.makeTransform(
              position,
              rotation,
              scale,
            );
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
  const entity = world.entity("test").model(.{.type = "torus"})
  .spawn(.{.source_model = "cube"})
  .color(128, 128, 128, 255);

  var system = System.init(&world);

  // When
  system.update();

  // Then
  if (entity.world.components.model.get(2)) |model| {
    try tst.expectEqual(rl.Matrix{
      .m0 = 0.1, .m1 = 0, .m2 = 0, .m3 = 0,
      .m4 = 0, .m5 = 0.1, .m6 = 0, .m7 = 0,
      .m8 = 0, .m9 = 0, .m10 = 0.1, .m11 = 0,
      .m12 = -0.5, .m13 = -0.5, .m14 = 0.5, .m15 = 1,
    }, model.transforms.?.items[0]);

    try tst.expectEqual(rl.Matrix{
      .m0 = 0.1, .m1 = 0, .m2 = 0, .m3 = 0,
      .m4 = 0, .m5 = 0.1, .m6 = 0, .m7 = 0,
      .m8 = 0, .m9 = 0, .m10 = 0.1, .m11 = 0,
      .m12 = 0.5, .m13 = -0.5, .m14 = 0.5, .m15 = 1,
    }, model.transforms.?.items[1]);
  }
  else
    return error.TestExpectedModel;
}
