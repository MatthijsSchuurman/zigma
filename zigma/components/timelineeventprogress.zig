const ecs = @import("../ecs.zig");

pub const Component = struct {
  progress: f32 = 0,
  target_id: ?ecs.EntityID,
};

pub fn activate(entity: ecs.Entity, target_id: ?ecs.EntityID) void {
  if (entity.world.components.timelineeventprogress.getPtr(entity.id)) |_| { // Already active
    return;
  }

  const new = .{.target_id = target_id};

  entity.world.components.timelineeventprogress.put(entity.id, new) catch @panic("Failed to store timeline event progress");
}

pub fn progress(entity: ecs.Entity, currentProgress: f32) void {
  if (entity.world.components.timelineeventprogress.getPtr(entity.id)) |existing| { // Already active
    existing.progress = currentProgress;
    return;
  }
}

pub fn deactivate(entity: ecs.Entity) void {
  _ = entity.world.components.timelineeventprogress.remove(entity.id);
}
