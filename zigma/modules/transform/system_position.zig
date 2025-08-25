const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");

const ComponentPosition = @import("component_position.zig");

pub const System = struct {
  world: *ecs.World,
  start_positions: std.AutoHashMap(ent.EntityID, ComponentPosition.Component),

  pub fn init(world: *ecs.World) System {
    var self = System{
      .world = world,
      .start_positions = undefined,
    };

    self.start_positions = std.AutoHashMap(ent.EntityID, ComponentPosition.Component).init(world.allocator);
    return self;
  }

  pub fn deinit(self: *System) void {
    self.start_positions.deinit();
  }

  pub fn update(self: *System) void {
    var it = self.world.components.timelineeventprogress.iterator();
    while(it.next()) |entry| {
      const id = entry.key_ptr.*;
      const event = entry.value_ptr.*;
      const target_id = event.target_id orelse continue;

      var start: ComponentPosition.Component = undefined;
      if (self.start_positions.get(id)) |cached| {
        start = cached;
      } else if (self.world.components.position.getPtr(target_id)) |target_position| { // Use current position of target entity
        self.start_positions.put(id, target_position.*) catch @panic("Fail to put start position");
        start = target_position.*;
      } else continue; // No start value

      if (self.world.components.position.getPtr(id)) |end|
        _ = self.world.entityWrap(target_id).position(
          start.x + ((end.x - start.x) * event.progress),
          start.y + ((end.y - start.y) * event.progress),
          start.z + ((end.z - start.z) * event.progress),
        );
    }
  }
};


// Testing
const tst = std.testing;

test "System should update position" {
  // Given
  const ComponentTimelineEventProgress = @import("../timeline/component_timelineeventprogress.zig");

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test").position(0, 0, 0);
  const event = world.entity("test event").position(1, -1, 100);

  const new = ComponentTimelineEventProgress.Component{.target_id = entity.id, .progress = 0.5};
  world.components.timelineeventprogress.put(event.id, new) catch @panic("Failed to store timeline event progress");

  var system = System.init(&world);
  defer system.deinit();

  // When
  system.update();

  // Then
  if (entity.world.components.position.get(entity.id)) |position|
    try tst.expectEqual(ComponentPosition.Component{.x = 0.5, .y = -0.5, .z = 50}, position)
   else
    return error.TestExpectedPosition;

  if (entity.world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(true, dirty.position)
   else
    return error.TestExpectedDirty;
}
