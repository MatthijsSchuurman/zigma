const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

pub const System = struct {
  world: *ecs.World,
  start_edges: std.AutoHashMap(ent.EntityID, ecs.Components.Edge.Component),

  pub fn init(world: *ecs.World) System {
    var self = System{
      .world = world,
      .start_edges = undefined,
    };

    self.start_edges = std.AutoHashMap(ent.EntityID, ecs.Components.Edge.Component).init(world.allocator);
    return self;
  }

  pub fn deinit(self: *System) void {
    self.start_edges.deinit();
  }

  pub fn update(self: *System) void {
    var it = self.world.components.timelineeventprogress.iterator();
    while(it.next()) |entry| {
      const id = entry.key_ptr.*;
      const event = entry.value_ptr.*;
      const target_id = event.target_id orelse continue;

      var start: ecs.Components.Edge.Component = undefined;
      if (self.start_edges.get(id)) |cached| {
        start = cached;
      } else if (self.world.components.edge.getPtr(target_id)) |target_edge| { // Use current edge of target entity
        self.start_edges.put(id, target_edge.*) catch @panic("Fail to put start edge");
        start = target_edge.*;
      } else continue; // No start value


      if (self.world.components.edge.get(id)) |end| {
        const ws: f32 = start.width;
        const we: f32 = end.width;

        const rs: f32 = @as(f32, @floatFromInt(start.color.r));
        const gs: f32 = @as(f32, @floatFromInt(start.color.g));
        const bs: f32 = @as(f32, @floatFromInt(start.color.b));
        const as: f32 = @as(f32, @floatFromInt(start.color.a));
        const re: f32 = @as(f32, @floatFromInt(end.color.r));
        const ge: f32 = @as(f32, @floatFromInt(end.color.g));
        const be: f32 = @as(f32, @floatFromInt(end.color.b));
        const ae: f32 = @as(f32, @floatFromInt(end.color.a));

        _ = self.world.entityWrap(target_id).edge(.{
          .width = (ws + ((we - ws) * event.progress)),
          .color = rl.Color{
            .r = @intFromFloat(@round(rs + ((re - rs) * event.progress))),
            .g = @intFromFloat(@round(gs + ((ge - gs) * event.progress))),
            .b = @intFromFloat(@round(bs + ((be - bs) * event.progress))),
            .a = @intFromFloat(@round(as + ((ae - as) * event.progress))),
          },
        });
      }
    }
  }
};


// Testing
const tst = std.testing;

test "System should update edge" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test").edge(.{.width = 1, .color = rl.Color{.r = 255, .g = 128, .b = 0, .a = 100}});
  const event = world.entity("test event").edge(.{.width = 2, .color = rl.Color{.r = 0, .g = 128, .b = 255, .a = 200}});

  const new = ecs.Components.TimelineEventProgress.Component{.target_id = entity.id, .progress = 0.5};
  world.components.timelineeventprogress.put(event.id, new) catch @panic("Failed to store timeline event progress");

  var system = System.init(&world);
  defer system.deinit();

  // When
  system.update();

  // Then
  if (entity.world.components.edge.get(entity.id)) |edge|
    try tst.expectEqual(ecs.Components.Edge.Component{.width = 1.5, .color = rl.Color{.r = 128, .g = 128, .b = 128, .a = 150}}, edge)
   else
    return error.TestExpectedEdge;
}
