const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");

pub const System = struct {
  world: *ecs.World,
  start_hides: std.AutoHashMap(ent.EntityID, bool),

  pub fn init(world: *ecs.World) System {
    var self = System{
      .world = world,
      .start_hides = undefined,
    };

    self.start_hides = std.AutoHashMap(ent.EntityID, bool).init(world.allocator);
    return self;
  }

  pub fn deinit(self: *System) void {
    self.start_hides.deinit();
  }

  pub fn update(self: *System) void {
    var it = self.world.components.timelineeventprogress.iterator();
    while(it.next()) |entry| {
      const id = entry.key_ptr.*;
      const event = entry.value_ptr.*;
      const target_id = event.target_id orelse continue;

      var start: bool = undefined;
      if (self.start_hides.get(id)) |cached| {
        start = cached;
      } else if (self.world.components.hide.getPtr(target_id)) |target_hide| { // Use current hide of target entity
        self.start_hides.put(id, target_hide.hidden) catch @panic("Fail to put start hide");
        start = target_hide.hidden;
      } else {
        self.start_hides.put(id, false) catch @panic("Fail to put start hide");
        start = false;
      }

      if (self.world.components.hide.getPtr(id)) |end| {
        if ((event.progress > 0.5 and end.hidden) or (event.progress < 0.5 and !end.hidden))
          _ = self.world.entityWrap(target_id).hide()
        else
          _ = self.world.entityWrap(target_id).unhide();
      }
    }
  }
};


// Testing
const tst = std.testing;

test "System should update hide" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test");
  const event = world.entity("test event").hide();

  const new = .{.target_id = entity.id, .progress = 0.5};
  world.components.timelineeventprogress.put(event.id, new) catch @panic("Failed to store timeline event progress");

  var system = System.init(&world);
  defer system.deinit();

  // When
  system.update();

  // Then
  if (entity.world.components.hide.get(entity.id)) |hide|
    try tst.expectEqual(false, hide.hidden)
   else
    return error.TestExpectedHide;


  // Given
  if (world.components.timelineeventprogress.getPtr(event.id)) |timelineeventprogress|
    timelineeventprogress.progress = 1.0;

  // When
  system.update();

  // Then
  if (entity.world.components.hide.get(entity.id)) |hide|
    try tst.expectEqual(true, hide.hidden)
   else
    return error.TestExpectedHide;
}
