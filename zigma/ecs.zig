const std = @import("std");
const components_position = @import("components/position.zig");

// World
pub const EntityID = u32;
pub const World = struct {
  allocator: std.mem.Allocator,

  next_id: EntityID = 0,
  entities: std.StringHashMap(EntityID),

  // Components
  positions: std.AutoHashMap(EntityID, components_position.Position),

  pub fn init(allocator: std.mem.Allocator) World {
    return World{
      .allocator = allocator,

      .entities = std.StringHashMap(u32).init(allocator),

      // Components
      .positions = std.AutoHashMap(u32, components_position.Position).init(allocator),
    };
  }

  pub fn deinit(self: *World) void {
    self.entities.deinit();

    // Components
    self.positions.deinit();
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
  pub fn render(_: *World) bool {
    return true;
  }
};

pub const Entity = struct {
  id: u32,
  world: *World,

  // Components
  pub const position = components_position.set;
};
