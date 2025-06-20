const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");

pub const System = struct {
  world: *ecs.World,
  start_rotations: std.AutoHashMap(ent.EntityID, ecs.Components.Rotation.Component),

  pub fn init(world: *ecs.World) System {
    var self = System{
      .world = world,
      .start_rotations = undefined,
    };

    self.start_rotations = std.AutoHashMap(ent.EntityID, ecs.Components.Rotation.Component).init(world.allocator);
    return self;
  }

  pub fn deinit(self: *System) void {
    self.start_rotations.deinit();
  }

  pub fn update(self: *System) void {
    var it = self.world.components.timelineeventprogress.iterator();
    while(it.next()) |entry| {
      const id = entry.key_ptr.*;
      const event = entry.value_ptr.*;
      const target_id = event.target_id orelse continue;

      var start: ecs.Components.Rotation.Component = undefined;
      if (self.start_rotations.get(id)) |cached| {
        start = cached;
      } else if (self.world.components.rotation.getPtr(target_id)) |target_rotation| { // Use current rotation of target entity
        self.start_rotations.put(id, target_rotation.*) catch @panic("Fail to put start rotation");
        start = target_rotation.*;
      } else continue; // No start value

      if (self.world.components.rotation.getPtr(id)) |end|
        _ = self.world.entityWrap(target_id).rotation(
          start.x + ((end.x - start.x) * event.progress),
          start.y + ((end.y - start.y) * event.progress),
          start.z + ((end.z - start.z) * event.progress),
        );
    }
  }
};


// Testing
const tst = std.testing;

test "System should update rotation" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test").rotation(0, 0, 0);
  const event = world.entity("test event").rotation(1, -1, 100);

  const new = ecs.Components.TimelineEventProgress.Component{.target_id = entity.id, .progress = 0.5};
  world.components.timelineeventprogress.put(event.id, new) catch @panic("Failed to store timeline event progress");

  var system = System.init(&world);
  defer system.deinit();

  // When
  system.update();

  // Then
  if (entity.world.components.rotation.get(entity.id)) |rotation|
    try tst.expectEqual(ecs.Components.Rotation.Component{.x = 0.5, .y = -0.5, .z = 50}, rotation)
   else
    return error.TestExpectedRotation;

  if (entity.world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(true, dirty.rotation)
   else
    return error.TestExpectedDirty;
}
