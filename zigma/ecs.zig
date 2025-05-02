const std = @import("std");

pub const components = struct {
  pub const position = @import("components/position.zig");
  pub const rotation = @import("components/rotation.zig");
  pub const scale = @import("components/scale.zig");
  pub const color = @import("components/color.zig");

  pub const text = @import("components/text.zig");
};

pub const systems = struct {
  pub const init = struct {
  };

  pub const deinit = struct {
  };

  pub const render = struct {
    pub const background = @import("systems/render/background.zig");
    pub const text = @import("systems/render/text.zig");
  };

  pub const input = struct {
  };
};

// World
pub const EntityID = u32;
pub const World = struct {
  allocator: std.mem.Allocator,

  next_id: EntityID = 0,
  entities: std.StringHashMap(EntityID),

  // Components
  positions: std.AutoHashMap(EntityID, components.position.Type),
  rotations: std.AutoHashMap(EntityID, components.rotation.Type),
  scales: std.AutoHashMap(EntityID, components.scale.Type),
  colors: std.AutoHashMap(EntityID, components.color.Type),

  texts: std.AutoHashMap(EntityID, components.text.Type),

  pub fn init(allocator: std.mem.Allocator) World {
    return World{
      .allocator = allocator,

      .entities = std.StringHashMap(u32).init(allocator),

      // Components
      .positions = std.AutoHashMap(u32, components.position.Type).init(allocator),
      .rotations = std.AutoHashMap(u32, components.rotation.Type).init(allocator),
      .scales = std.AutoHashMap(u32, components.scale.Type).init(allocator),
      .colors = std.AutoHashMap(u32, components.color.Type).init(allocator),

      .texts = std.AutoHashMap(u32, components.text.Type).init(allocator),
    };
  }

  pub fn deinit(self: *World) void {
    self.entities.deinit();

    // Components
    self.positions.deinit();
    self.rotations.deinit();
    self.scales.deinit();
    self.colors.deinit();

    self.texts.deinit();
  }

  // Entity
  pub fn entity(self: *World, name: []const u8) Entity {
    const e = self.entities.getOrPut(name) catch @panic("Unable to create entity");
    if (!e.found_existing) {
      e.value_ptr.* = self.next_id;
      self.next_id += 1;
    }

    return Entity{
      .id = e.value_ptr.*,
      .world = self,
    };
  }

  // Render
  pub fn render(self: *World) bool {
    systems.render.text.run(self);
    return true;
  }
};

pub const Entity = struct {
  id: u32,
  world: *World,

  pub const com_position = components.position.set;
  pub const com_rotation = components.rotation.set;
  pub const com_scale = components.scale.set;
  pub const com_color = components.color.set;

  pub const com_text = components.text.set;
};
