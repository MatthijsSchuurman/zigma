const ecs = @import("ecs.zig");

const EntityDirty = @import("entity/dirty.zig");

const EntityTimeline = @import("entity/timeline.zig");
const EntityTimelineEvent = @import("entity/timelineevent.zig");

const EntityCamera = @import("entity/camera.zig");

const EntitySpawn = @import("entity/spawn.zig");
const EntityPosition = @import("entity/position.zig");
const EntityRotation = @import("entity/rotation.zig");
const EntityScale = @import("entity/scale.zig");
const EntityColor = @import("entity/color.zig");

const EntityShader = @import("entity/shader.zig");
const EntityLight = @import("entity/light.zig");
const EntityMaterial = @import("entity/material.zig");

const EntityModel = @import("entity/model.zig");
const EntityText = @import("entity/text.zig");

//Entity
pub const EntityID = u32;
pub const Entity = struct {
  id: EntityID,
  parent_id: EntityID = 0,
  world: *ecs.World,

  pub const dirty = EntityDirty.set;

  pub const timeline = EntityTimeline.init;
  pub const timeline_speed = EntityTimeline.setSpeed;
  pub const timeline_offset = EntityTimeline.setOffset;
  pub const event = EntityTimelineEvent.add;

  pub const camera = EntityCamera.init;
  pub const camera_activate = EntityCamera.activate;
  pub const camera_deactivate = EntityCamera.deactivate;
  pub const camera_target = EntityCamera.target;
  pub const camera_fovy = EntityCamera.fovy;

  pub const position = EntityPosition.set;
  pub const rotation = EntityRotation.set;
  pub const scale = EntityScale.set;
  pub const color = EntityColor.set;

  pub const spawn = EntitySpawn.init;
  pub const shader = EntityShader.init;
  pub const light = EntityLight.init;
  pub const material = EntityMaterial.init;

  pub const model = EntityModel.init;
  pub const model_transform = EntityModel.transform;
  pub const text = EntityText.set;

  pub fn deinit(entity: Entity) void {
    EntitySpawn.deinit(entity);
    EntityModel.deinit(entity);
    EntityMaterial.deinit(entity);
    EntityShader.deinit(entity);
  }
};
