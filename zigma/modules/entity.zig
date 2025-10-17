const ecs = @import("../ecs.zig");

const ModuleTimeline = @import("timeline/module.zig").Module;
const ModuleMusic = @import("music/module.zig").Module;
const ModuleSubWorld = @import("subworld/module.zig").Module;

const ModuleDirty = @import("dirty/module.zig").Module;
const ModuleCamera = @import("camera/module.zig").Module;

const ModuleSpawn = @import("spawn/module.zig").Module;
const ModulePosition = @import("transform/module.zig").Module;
const ModuleRotation = @import("transform/module.zig").Module;
const ModuleScale = @import("transform/module.zig").Module;
const ModuleColor = @import("color/module.zig").Module;
const ModuleEdge = @import("edge/module.zig").Module;
const ModuleHide = @import("hide/module.zig").Module;

const ModuleShader = @import("shader/module.zig").Module;
const ModuleLight = @import("light/module.zig").Module;
const ModuleMaterial = @import("material/module.zig").Module;

const ModuleModel = @import("model/module.zig").Module;
const ModuleText = @import("text/module.zig").Module;
const ModuleFPS = @import("fps/module.zig").Module;

//Entity
pub const Entity = struct {
  id: ecs.EntityID,
  parent_id: ecs.EntityID = 0,
  world: *ecs.World,

  pub const timeline = ModuleTimeline.Entities.Timeline.init;
  pub const timeline_speed = ModuleTimeline.Entities.Timeline.setSpeed;
  pub const timeline_offset = ModuleTimeline.Entities.Timeline.setOffset;
  pub const event = ModuleTimeline.Entities.TimelineEvent.add;

  pub const music = ModuleMusic.Entities.Music.init;
  pub const subWorld = ModuleSubWorld.Entities.SubWorld.init;

  pub const dirty = ModuleDirty.Entities.Dirty.set;
  pub const camera = ModuleCamera.Entities.Camera.init;
  pub const camera_activate = ModuleCamera.Entities.Camera.activate;
  pub const camera_deactivate = ModuleCamera.Entities.Camera.deactivate;
  pub const camera_target = ModuleCamera.Entities.Camera.target;
  pub const camera_fovy = ModuleCamera.Entities.Camera.fovy;

  pub const position = ModulePosition.Entities.Position.set;
  pub const rotation = ModuleRotation.Entities.Rotation.set;
  pub const scale = ModuleScale.Entities.Scale.set;
  pub const color = ModuleColor.Entities.Color.set;
  pub const edge = ModuleEdge.Entities.Edge.set;
  pub const hide = ModuleHide.Entities.Hide.hide;
  pub const unhide = ModuleHide.Entities.Hide.unhide;

  pub const spawn = ModuleSpawn.Entities.Spawn.init;
  pub const shader = ModuleShader.Entities.Shader.init;
  pub const light = ModuleLight.Entities.Light.init;
  pub const material = ModuleMaterial.Entities.Material.init;

  pub const model = ModuleModel.Entities.Model.init;
  pub const text = ModuleText.Entities.Text.set;
  pub const fps = ModuleFPS.Entities.FPS.init;

  pub fn deinit(entity: Entity) void {
    ModuleSpawn.Entities.Spawn.deinit(entity);
    ModuleModel.Entities.Model.deinit(entity);
    ModuleMaterial.Entities.Material.deinit(entity);
    ModuleShader.Entities.Shader.deinit(entity);
  }
};
