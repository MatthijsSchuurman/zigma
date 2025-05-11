const std = @import("std");
const ecs = @import("../../ecs.zig");

pub const System = struct {
  world: *ecs.World,
  start_rotations: std.AutoHashMap(ecs.EntityID, ecs.Components.Rotation.Component),

  pub fn init(world: *ecs.World) System {
    var self = System{
      .world = world,
      .start_rotations = undefined,
    };

    self.start_rotations = std.AutoHashMap(ecs.EntityID, ecs.Components.Rotation.Component).init(world.allocator);
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
      } else if (self.world.components.rotation.get(target_id)) |target_rotation| { // Use current rotation of target entity
        self.start_rotations.put(id, target_rotation) catch @panic("Fail to put start rotation");
        start = target_rotation;
      }

      if (self.world.components.rotation.get(id)) |end| {
        const new_postion = ecs.Components.Rotation.Component{
          .x = start.x + ((end.x - start.x) * event.progress),
          .y = start.y + ((end.y - start.y) * event.progress),
          .z = start.z + ((end.z - start.z) * event.progress),
        };

        if (self.world.components.rotation.getPtr(target_id)) |target_rotation| {
          target_rotation.* = new_postion;
        }
      }
    }
  }
};
