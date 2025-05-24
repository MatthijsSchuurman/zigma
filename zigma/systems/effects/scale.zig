const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");

pub const System = struct {
  world: *ecs.World,
  start_scales: std.AutoHashMap(ent.EntityID, ecs.Components.Scale.Component),

  pub fn init(world: *ecs.World) System {
    var self = System{
      .world = world,
      .start_scales = undefined,
    };

    self.start_scales = std.AutoHashMap(ent.EntityID, ecs.Components.Scale.Component).init(world.allocator);
    return self;
  }

  pub fn deinit(self: *System) void {
    self.start_scales.deinit();
  }

  pub fn update(self: *System) void {
    var it = self.world.components.timelineeventprogress.iterator();
    while(it.next()) |entry| {
      const id = entry.key_ptr.*;
      const event = entry.value_ptr.*;
      const target_id = event.target_id orelse continue;

      var start: ecs.Components.Scale.Component = undefined;
      if (self.start_scales.get(id)) |cached| {
        start = cached;
      } else if (self.world.components.scale.get(target_id)) |target_scale| { // Use current scale of target entity
        self.start_scales.put(id, target_scale) catch @panic("Fail to put start scale");
        start = target_scale;
      }

      if (self.world.components.scale.get(id)) |end|
        _ = self.world.entityWrap(target_id).scale(
          start.x + ((end.x - start.x) * event.progress),
          start.y + ((end.y - start.y) * event.progress),
          start.z + ((end.z - start.z) * event.progress),
        );
    }
  }
};


// Testing
const tst = std.testing;

test "System should update scale" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test").scale(0, 0, 0);
  const event = world.entity("test event").scale(1, -1, 100);

  const new = .{.target_id = entity.id, .progress = 0.5};
  world.components.timelineeventprogress.put(event.id, new) catch @panic("Failed to store timeline event progress");

  var system = System.init(&world);
  defer system.deinit();

  // When
  system.update();

  // Then
  if (entity.world.components.scale.get(entity.id)) |scale|
    try tst.expectEqual(ecs.Components.Scale.Component{.x = 0.5, .y = -0.5, .z = 50}, scale)
   else
    return error.TestExpectedScale;

  if (entity.world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(true, dirty.scale)
   else
    return error.TestExpectedDirty;
}
