const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");

const ComponentColor = @import("component.zig");

pub const System = struct {
  world: *ecs.World,
  start_colors: std.AutoHashMap(ent.EntityID, ComponentColor.Component),

  pub fn init(world: *ecs.World) System {
    var self = System{
      .world = world,
      .start_colors = undefined,
    };

    self.start_colors = std.AutoHashMap(ent.EntityID, ComponentColor.Component).init(world.allocator);
    return self;
  }

  pub fn deinit(self: *System) void {
    self.start_colors.deinit();
  }

  pub fn update(self: *System) void {
    var it = self.world.components.timelineeventprogress.iterator();
    while(it.next()) |entry| {
      const id = entry.key_ptr.*;
      const event = entry.value_ptr.*;
      const target_id = event.target_id orelse continue;

      var start: ComponentColor.Component = undefined;
      if (self.start_colors.get(id)) |cached| {
        start = cached;
      } else if (self.world.components.color.getPtr(target_id)) |target_color| { // Use current color of target entity
        self.start_colors.put(id, target_color.*) catch @panic("Fail to put start color");
        start = target_color.*;
      } else continue; // No start value


      if (self.world.components.color.get(id)) |end| {
        const rs: f32 = @as(f32, @floatFromInt(start.r));
        const gs: f32 = @as(f32, @floatFromInt(start.g));
        const bs: f32 = @as(f32, @floatFromInt(start.b));
        const as: f32 = @as(f32, @floatFromInt(start.a));
        const re: f32 = @as(f32, @floatFromInt(end.r));
        const ge: f32 = @as(f32, @floatFromInt(end.g));
        const be: f32 = @as(f32, @floatFromInt(end.b));
        const ae: f32 = @as(f32, @floatFromInt(end.a));

        _ = self.world.entityWrap(target_id).color(
          @intFromFloat(@round(rs + ((re - rs) * event.progress))),
          @intFromFloat(@round(gs + ((ge - gs) * event.progress))),
          @intFromFloat(@round(bs + ((be - bs) * event.progress))),
          @intFromFloat(@round(as + ((ae - as) * event.progress))),
        );
      }
    }
  }
};


// Testing
const tst = std.testing;

test "System should update color" {
  // Given
  const ComponentTimelineEventProgress = @import("../timeline/component_timelineeventprogress.zig");

  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test").color(255, 128, 0, 100);
  const event = world.entity("test event").color(0, 128, 255, 200);

  const new = ComponentTimelineEventProgress.Component{.target_id = entity.id, .progress = 0.5};
  world.components.timelineeventprogress.put(event.id, new) catch @panic("Failed to store timeline event progress");

  var system = System.init(&world);
  defer system.deinit();

  // When
  system.update();

  // Then
  if (entity.world.components.color.get(entity.id)) |color|
    try tst.expectEqual(ComponentColor.Component{.r = 128, .g = 128, .b = 128, .a = 150}, color)
   else
    return error.TestExpectedColor;

  if (entity.world.components.dirty.get(entity.id)) |dirty|
    try tst.expectEqual(true, dirty.color)
   else
    return error.TestExpectedDirty;
}
