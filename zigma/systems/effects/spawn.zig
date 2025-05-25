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

      if (self.world.components.dirty.get(id)) |dirty| {
        if (dirty.position or dirty.rotation or dirty.scale) { // Model dirty
          _ = self.world.entityWrap(id).model_transform( // Pre transform model, redone by model system
            self.world.components.position.get(id) orelse unreachable,
            self.world.components.rotation.get(id) orelse unreachable,
            self.world.components.scale.get(id) orelse unreachable,
          );

          const model = self.world.components.model.get(id) orelse unreachable;
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

  const entity = world.entity("test").position(0, 0, 0);
  const event = world.entity("test event").position(1, -1, 100);

  const new = .{.target_id = entity.id, .progress = 0.5};
  world.components.timelineeventprogress.put(event.id, new) catch @panic("Failed to store timeline event progress");

  var system = System.init(&world);

  // When
  system.update();

  // Then
  if (entity.world.components.position.get(entity.id)) |position|
    try tst.expectEqual(ecs.Components.Position.Component{.x = 0.5, .y = -0.5, .z = 50}, position)
   else
    return error.TestExpectedPosition;

  if (entity.world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(true, dirty.position)
   else
    return error.TestExpectedDirty;
}
