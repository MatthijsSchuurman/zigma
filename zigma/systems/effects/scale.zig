const rl = @cImport(@cInclude("raylib.h"));
const ecs = @import("../../ecs.zig");
const std = @import("std");

pub const System = struct {
  world: *ecs.World,
  start_scales: std.AutoHashMap(ecs.EntityID, ecs.Components.Scale.Component),

  pub fn init(world: *ecs.World) System {
    var self = System{
      .world = world,
      .start_scales = undefined,
    };

    self.start_scales = std.AutoHashMap(ecs.EntityID, ecs.Components.Scale.Component).init(world.allocator);
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

      if (self.world.components.scale.get(id)) |end| {
        const new_postion = ecs.Components.Scale.Component{
          .x = start.x + ((end.x - start.x) * event.progress),
          .y = start.y + ((end.y - start.y) * event.progress),
          .z = start.z + ((end.z - start.z) * event.progress),
        };

        if (self.world.components.scale.getPtr(target_id)) |target_scale| {
          target_scale.* = new_postion;
        }
      }
    }
  }
};
