const rl = @cImport(@cInclude("raylib.h"));
const ecs = @import("../../ecs.zig");
const std = @import("std");

pub const System = struct {
  world: *ecs.World,
  start_sizes: std.AutoHashMap(ecs.EntityID, ecs.Components.Size.Component),

  pub fn init(world: *ecs.World) System {
    var self = System{
      .world = world,
      .start_sizes = undefined,
    };

    self.start_sizes = std.AutoHashMap(ecs.EntityID, ecs.Components.Size.Component).init(world.allocator);
    return self;
  }

  pub fn deinit(self: *System) void {
    self.start_sizes.deinit();
  }

  pub fn update(self: *System) void {
    var it = self.world.components.timelineeventprogress.iterator();

    while(it.next()) |entry| {
      const id = entry.key_ptr.*;
      const event = entry.value_ptr.*;
      const target_id = event.target_id orelse continue;

      var start: ecs.Components.Size.Component = undefined;
      if (self.start_sizes.get(id)) |cached| {
        start = cached;
      } else if (self.world.components.size.get(target_id)) |target_size| { // Use current size of target entity
        self.start_sizes.put(id, target_size) catch @panic("Fail to put start size");
        start = target_size;
      }

      if (self.world.components.size.get(id)) |end| {
        const new_postion = ecs.Components.Size.Component{
          .x = start.x + ((end.x - start.x) * event.progress),
          .y = start.y + ((end.y - start.y) * event.progress),
          .z = start.z + ((end.z - start.z) * event.progress),
        };

        if (self.world.components.size.getPtr(target_id)) |target_size| {
          target_size.* = new_postion;
        }
      }
    }
  }
};
