const std = @import("std");

//Entity
pub const EntityID = u32;
pub const Entity = struct {
  id: EntityID,
  parent_id: EntityID,
  world: *World,

  pub const timeline_init = Components.Timeline.init;
  pub const timeline_speed = Components.Timeline.setSpeed;
  pub const event = Components.TimelineEvent.add;

  pub const position = Components.Position.set;
  pub const rotation = Components.Rotation.set;
  pub const size = Components.Size.set;

  pub const color = Components.Color.set;

  pub const text = Components.Text.set;
};


//Components
pub const Components = struct {
  pub const Timeline = @import("components/timeline.zig");
  pub const TimelineEvent = @import("components/timelineevent.zig");
  pub const TimelineEventProgress = @import("components/timelineeventprogress.zig");

  pub const Position = @import("components/position.zig");
  pub const Rotation = @import("components/rotation.zig");
  pub const Size = @import("components/size.zig");

  pub const Color = @import("components/color.zig");

  pub const Text = @import("components/text.zig");
};

const ComponentDeclarations = std.meta.declarations(Components); // Needed to prevent: unable to resolve comptime value

comptime { // Check component definitions
  for (ComponentDeclarations) |declaration| {
    const C = @field(Components, declaration.name);

    if (!@hasDecl(C, "Data"))
      @compileError("Component " ++ @typeName(C) ++ " Data missing");
  }
}


//Systems
pub const Systems = struct {
  pub const Init = struct {
  };

  pub const Deinit = struct {
  };

  pub const Timeline = @import("systems/timeline.zig");

  pub const Render = struct {
    pub const Background = @import("systems/render/background.zig");
    pub const Text = @import("systems/render/text.zig");
  };

  pub const Effects = struct {
  };

  pub const Input = struct {
  };
};


// World
pub const World = struct {
  allocator: std.mem.Allocator,

  entity_id: EntityID = 0,
  entities: std.StringHashMap(EntityID),

  components: ComponentStores(),

  pub fn init(allocator: std.mem.Allocator) World {
    var self = World{
      .allocator = allocator,
      .entities = std.StringHashMap(EntityID).init(allocator),
      .components = undefined,
    };

    inline for (ComponentDeclarations) |declaration| {
      const T = @field(Components, declaration.name).Data;
      @field(self.components, toLower(declaration.name)) = std.AutoHashMap(EntityID, *T).init(allocator);
    }

    return self;
  }

  pub fn deinit(self: *World) void {
    self.entities.deinit();

    inline for (ComponentDeclarations) |declaration| {
      var it2 = @field(self.components, toLower(declaration.name)).iterator();
      while (it2.next()) |entry|
        self.allocator.destroy(entry.value_ptr.*);

      @field(self.components, toLower(declaration.name)).deinit();
    }
  }

  // Entity
  pub fn entityNext(self: *World) EntityID {
    defer self.entity_id += 1;
    return self.entity_id;
  }

  pub fn entity(self: *World, name: []const u8) Entity {
    if (self.entities.get(name)) |id| // Existing named entity
      return Entity{
        .id = id,
        .parent_id = 0,
        .world = self,
      };

    const id = self.entityNext();
    self.entities.put(name, id) catch @panic("Failed to store entity mapping");
    return Entity{
      .id = id,
      .parent_id = 0,
      .world = self,
    };
  }

  // Render
  pub fn render(self: *World) bool {
    Systems.Timeline.run(self);
    Systems.Render.Text.run(self);
    return true;
  }
};


// Utils
fn ComponentStores() type {
  const ds = std.meta.declarations(Components);
  var f: [ds.len]std.builtin.Type.StructField = undefined;

  inline for (ds, 0..) |d, i| {
    const T = @field(Components, d.name).Data;
    f[i] = .{
      .name          = toLower(d.name),
      .type          = std.AutoHashMap(EntityID, *T),
      .default_value = null,
      .is_comptime   = false,
      .alignment     = 0,
    };
  }

  return @Type(.{ .Struct = .{
    .layout   = .auto,
    .fields   = &f,
    .decls    = &.{},
    .is_tuple = false,
  }});
}

fn toLower(comptime s: []const u8) [:0]const u8 {
  var buf: [s.len + 1]u8 = undefined;
  for (s, 0..) |c, i|
    buf[i] = std.ascii.toLower(c);

  buf[s.len] = 0;
  return buf[0..s.len :0];
}
