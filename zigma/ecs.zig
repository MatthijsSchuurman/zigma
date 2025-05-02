const std = @import("std");

const components = @import("components.zig");
const systems = @import("systems.zig");

// World
pub const EntityID = u32;
pub const World = struct {
  allocator: std.mem.Allocator,

  next_id: EntityID = 0,
  entities: std.StringHashMap(EntityID),

  // Components
  positions: std.AutoHashMap(EntityID, components.position.Type),
  texts: std.AutoHashMap(EntityID, components.text.Type),

  pub fn init(allocator: std.mem.Allocator) World {
    return World{
      .allocator = allocator,

      .entities = std.StringHashMap(u32).init(allocator),

      // Components
      .positions = std.AutoHashMap(u32, components.position.Type).init(allocator),
      .texts = std.AutoHashMap(u32, components.text.Type).init(allocator),
    };
  }

  pub fn deinit(self: *World) void {
    self.entities.deinit();

    // Components
    self.positions.deinit();
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
  pub const com_text = components.text.set;
};
