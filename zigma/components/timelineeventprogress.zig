const ecs = @import("../ecs.zig");

pub const Data = struct {
  progress: f32 = 0,
};

pub fn activate(entity: *const ecs.Entity) void {
  if (entity.world.components.timelineEventProgress.get(entity.id)) |_| {
    return;
  }

  const timelineEventProgress = entity.world.allocator.create(Data) catch @panic("Failed to create timelineEventProgress");
  timelineEventProgress.* = .{};

  entity.world.components.timelineEventProgress.put(entity.id, timelineEventProgress) catch @panic("Failed to store timelineEventProgress");
}

pub fn progress(entity: *const ecs.Entity, currentProgress: f32) void {
  if (entity.world.components.timelineeventprogress.get(entity.id)) |timelineEventProgress|
    timelineEventProgress.progress=currentProgress;
}

pub fn deactivate(entity: *const ecs.Entity) void {
  if (entity.world.components.timelineeventprogress.fetchRemove(entity.id)) |timelineEventProgress|
    entity.world.allocator.destroy(timelineEventProgress);
}
