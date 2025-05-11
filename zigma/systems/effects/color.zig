const std = @import("std");
const ecs = @import("../../ecs.zig");

pub const System = struct {
  world: *ecs.World,
  start_colors: std.AutoHashMap(ecs.EntityID, ecs.Components.Color.Component),

  pub fn init(world: *ecs.World) System {
    var self = System{
      .world = world,
      .start_colors = undefined,
    };

    self.start_colors = std.AutoHashMap(ecs.EntityID, ecs.Components.Color.Component).init(world.allocator);
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

      var start: ecs.Components.Color.Component = undefined;
      if (self.start_colors.get(id)) |cached| {
        start = cached;
      } else if (self.world.components.color.get(target_id)) |target_color| { // Use current color of target entity
        self.start_colors.put(id, target_color) catch @panic("Fail to put start color");
        start = target_color;
      }

      if (self.world.components.color.get(id)) |end| {
        const rs: f32 = @as(f32, @floatFromInt(start.r));
        const gs: f32 = @as(f32, @floatFromInt(start.g));
        const bs: f32 = @as(f32, @floatFromInt(start.b));
        const as: f32 = @as(f32, @floatFromInt(start.a));
        const re: f32 = @as(f32, @floatFromInt(end.r));
        const ge: f32 = @as(f32, @floatFromInt(end.g));
        const be: f32 = @as(f32, @floatFromInt(end.b));
        const ae: f32 = @as(f32, @floatFromInt(end.a));

        const new_postion = ecs.Components.Color.Component{
          .r = @intFromFloat(@round(rs + ((re - rs) * event.progress))),
          .g = @intFromFloat(@round(gs + ((ge - gs) * event.progress))),
          .b = @intFromFloat(@round(bs + ((be - bs) * event.progress))),
          .a = @intFromFloat(@round(as + ((ae - as) * event.progress))),
        };

        if (self.world.components.color.getPtr(target_id)) |target_color| {
          target_color.* = new_postion;
        }
      }
    }
  }
};
