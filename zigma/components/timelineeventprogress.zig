const ecs = @import("../ecs.zig");

pub const Data = struct {
  progress: f32 = 0,
};

pub fn progress(entity: ecs.Entity, currentProgress: f32) void {
  if (entity.world.components.timelineeventprogress.getPtr(entity.id)) |timelineEventProgress| { // Already active
    timelineEventProgress.progress = currentProgress;
    return;
  }

  //Activate
  const timelineEventProgress = .{.progress = currentProgress};

  entity.world.components.timelineeventprogress.put(entity.id, timelineEventProgress) catch @panic("Failed to store timeline event progress");
}

pub fn deactivate(entity: ecs.Entity) void {
  _ = entity.world.components.timelineeventprogress.remove(entity.id);
}
