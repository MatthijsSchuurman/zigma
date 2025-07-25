const ecs = @import("ecs.zig");

const EntityTimeline = @import("entity/timeline.zig");
const EntityTimelineEvent = @import("entity/timelineevent.zig");
const EntityMusic = @import("entity/music.zig");
const EntitySubWorld = @import("entity/subworld.zig");

const EntityDirty = @import("entity/dirty.zig");
const EntityCamera = @import("entity/camera.zig");

const EntitySpawn = @import("entity/spawn.zig");
const EntityPosition = @import("entity/position.zig");
const EntityRotation = @import("entity/rotation.zig");
const EntityScale = @import("entity/scale.zig");
const EntityColor = @import("entity/color.zig");
const EntityEdge = @import("entity/edge.zig");
const EntityHide = @import("entity/hide.zig");

const EntityShader = @import("entity/shader.zig");
const EntityLight = @import("entity/light.zig");
const EntityMaterial = @import("entity/material.zig");

const EntityModel = @import("entity/model.zig");
const EntityText = @import("entity/text.zig");
const EntityFPS = @import("entity/fps.zig");

//Entity
pub const EntityID = u32;
pub const Entity = struct {
  id: EntityID,
  parent_id: EntityID = 0,
  world: *ecs.World,

  pub const timeline = EntityTimeline.init;
  pub const timeline_speed = EntityTimeline.setSpeed;
  pub const timeline_offset = EntityTimeline.setOffset;
  pub const event = EntityTimelineEvent.add;
  pub const music = EntityMusic.init;
  pub const subWorld = EntitySubWorld.init;

  pub const dirty = EntityDirty.set;
  pub const camera = EntityCamera.init;
  pub const camera_activate = EntityCamera.activate;
  pub const camera_deactivate = EntityCamera.deactivate;
  pub const camera_target = EntityCamera.target;
  pub const camera_fovy = EntityCamera.fovy;

  pub const position = EntityPosition.set;
  pub const rotation = EntityRotation.set;
  pub const scale = EntityScale.set;
  pub const color = EntityColor.set;
  pub const edge = EntityEdge.set;
  pub const hide = EntityHide.hide;
  pub const unhide = EntityHide.unhide;

  pub const spawn = EntitySpawn.init;
  pub const shader = EntityShader.init;
  pub const light = EntityLight.init;
  pub const material = EntityMaterial.init;

  pub const model = EntityModel.init;
  pub const text = EntityText.set;
  pub const fps = EntityFPS.init;

  pub fn deinit(entity: Entity) void {
    EntitySpawn.deinit(entity);
    EntityModel.deinit(entity);
    EntityMaterial.deinit(entity);
    EntityShader.deinit(entity);
  }
};
