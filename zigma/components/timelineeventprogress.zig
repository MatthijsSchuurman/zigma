const ecs = @import("../ecs.zig");

pub const Data = struct {
  progress: f32 = 0,
};

pub fn progress(entity: ecs.Entity, currentProgress: f32) void {
  if (entity.world.components.timelineeventprogress.getPtr(entity.id)) |existing| { // Already active
    existing.progress = currentProgress;
    return;
  }

  //Activate
  const new = .{.progress = currentProgress};

  entity.world.components.timelineeventprogress.put(entity.id, new) catch @panic("Failed to store timeline event progress");
}

pub fn deactivate(entity: ecs.Entity) void {
  _ = entity.world.components.timelineeventprogress.remove(entity.id);
}
