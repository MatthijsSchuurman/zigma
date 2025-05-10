const std = @import("std");

//Entity
pub const EntityID = u32;
pub const Entity = struct {
  id: EntityID,
  parent_id: EntityID = 0,
  world: *World,

  pub const timeline_init = Components.Timeline.init;
  pub const timeline_speed = Components.Timeline.setSpeed;
  pub const timeline_offset = Components.Timeline.setOffset;
  pub const event = Components.TimelineEvent.add;

  pub const position = Components.Position.set;
  pub const rotation = Components.Rotation.set;
  pub const scale = Components.Scale.set;

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
  pub const Scale = @import("components/scale.zig");
  pub const Color = @import("components/color.zig");

  pub const Text = @import("components/text.zig");
};

const ComponentDeclarations = std.meta.declarations(Components); // Needed to prevent: unable to resolve comptime value


//Systems
pub const Systems = struct {
  pub const Timeline = @import("systems/timeline.zig");
  pub const FPS = @import("systems/fps.zig");

  // Effects
  pub const Effects_Position = @import("systems/effects/position.zig");
  pub const Effects_Rotation = @import("systems/effects/rotation.zig");
  pub const Effects_Scale = @import("systems/effects/scale.zig");
  pub const Effects_Color = @import("systems/effects/color.zig");

  // Render
  pub const Render_Background = @import("systems/render/background.zig");
  pub const Render_Text = @import("systems/render/text.zig");
};

const SystemDeclarations = std.meta.declarations(Systems); // Needed to prevent: unable to resolve comptime value


// World
pub const World = struct {
  allocator: std.mem.Allocator,

  entity_id: EntityID = 1, // 0 is no entry
  entities: std.StringHashMap(EntityID),

  components: ComponentStores(),
  systems: SystemStores(),

  pub fn init(allocator: std.mem.Allocator) World {
    var self = World{
      .allocator = allocator,
      .entities = std.StringHashMap(EntityID).init(allocator),
      .components = undefined,
      .systems = undefined,
    };

    inline for (ComponentDeclarations) |declaration| {
      const T = @field(Components, declaration.name).Component;
      @field(self.components, toLower(declaration.name)) = std.AutoHashMap(EntityID, T).init(allocator);
    }

    return self;
  }

  pub fn initSystems(self: *World) void {
    inline for (SystemDeclarations) |declaration| {
      const T = @field(Systems, declaration.name).System;
      @field(self.systems, toLower(declaration.name)) = T.init(self);
    }
  }

  pub fn deinit(self: *World) void {
    self.entities.deinit();

    inline for (ComponentDeclarations) |declaration|
      @field(self.components, toLower(declaration.name)).deinit();

    inline for (SystemDeclarations) |declaration| {
      const T = @field(Systems, declaration.name).System;

      if (@hasDecl(T, "deinit"))
        @field(self.systems, toLower(declaration.name)).deinit();
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
    self.systems.timeline.update();

    self.systems.effects_position.update();
    self.systems.effects_rotation.update();
    self.systems.effects_scale.update();
    self.systems.effects_color.update();

    self.systems.render_background.update();
    self.systems.render_text.update();

    self.systems.fps.update();
    return true;
  }

  //Components
  pub fn query(self: *World, comptime T: type, component: *const std.AutoHashMap(EntityID, T.Data), filter: T.Filter, sort: []const T.Sort) []EntityID {
    var results = std.ArrayList(EntityID).init(self.allocator);

    var it = component.iterator();
    while (it.next()) |entry|
      if (T.filter(entry.value_ptr.*, filter))
        results.append(entry.key_ptr.*) catch @panic("Failed to append query result");

    if (@hasDecl(T, "compare") and sort.len > 0) {
      const Context = struct {
        component: *const std.AutoHashMap(EntityID, T.Data),
        sort: []const T.Sort,
      };

      const context = Context {
        .component = component,
        .sort = sort,
      };

      std.sort.heap(EntityID, results.items, context, struct {
        fn lessThan(ctx: Context, a: EntityID, b: EntityID) bool {
          const va = ctx.component.get(a).?;
          const vb = ctx.component.get(b).?;
          return T.compare(va, vb, ctx.sort) == .lt;
        }
      }.lessThan);
    }

    return results.toOwnedSlice() catch @panic("Failed to convert result to slice");
  }
};


// Utils
fn ComponentStores() type {
  const ds = std.meta.declarations(Components);
  var f: [ds.len]std.builtin.Type.StructField = undefined;

  inline for (ds, 0..) |d, i| {
    const T = @field(Components, d.name).Component;
    f[i] = .{
      .name          = toLower(d.name),
      .type          = std.AutoHashMap(EntityID, T),
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

fn SystemStores() type {
  const ds = std.meta.declarations(Systems);
  var f: [ds.len]std.builtin.Type.StructField = undefined;

  inline for (ds, 0..) |d, i| {
    const T = @field(Systems, d.name).System;
    f[i] = .{
      .name          = toLower(d.name),
      .type          = T,
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

pub fn toLower(comptime s: []const u8) [:0]const u8 {
  var buf: [s.len + 1]u8 = undefined;
  for (s, 0..) |c, i|
    buf[i] = std.ascii.toLower(c);

  buf[s.len] = 0;
  return buf[0..s.len :0];
}

// Filter functions
pub fn FieldFilter(comptime T: type) type {
  return union(enum) {
    eq: T,
    not: T,
    lt: T,
    lte: T,
    gt: T,
    gte: T,
  };
}

pub fn matchField(comptime T: type, actual: T, cond: FieldFilter(T)) bool {
  if (T == []const u8)
    return switch (cond) {
      .eq => std.mem.eql(u8, actual, cond.eq),
      .not => !std.mem.eql(u8, actual, cond.not),
      .lt => false,
      .lte => false,
      .gt => false,
      .gte => false,
    };

  if (@typeInfo(T) == .Optional)
    return switch (cond) {
      .eq => actual != null and cond.eq != null and actual.? == cond.eq.?,
      .not => actual != null and cond.not != null and actual.? != cond.not.?,
      .lt => actual != null and cond.lt != null and actual.? < cond.lt.?,
      .lte => actual != null and cond.lte != null and actual.? <= cond.lte.?,
      .gt => actual != null and cond.gt != null and actual.? > cond.gt.?,
      .gte => actual != null and cond.gte != null and actual.? >= cond.gte.?,
    };

  return switch (cond) {
    .eq => actual == cond.eq,
    .not => actual != cond.not,
    .lt => actual < cond.lt,
    .lte => actual <= cond.lte,
    .gt => actual > cond.gt,
    .gte => actual >= cond.gte,
  };
}


// Testing
const tst = std.testing;

test "ECS World should init" {
  // Given
  const allocator = std.testing.allocator;

  // When
  var world = World.init(allocator);
  defer world.deinit();

  // Then
  try tst.expectEqual(world.entity_id, 1);
  try tst.expectEqual(world.entities.count(), 0);
  try tst.expectEqual(world.components.timeline.count(), 0);
}

test "ECS World should init systems" {
  // Given
  const allocator = std.testing.allocator;
  var world = World.init(allocator);
  defer world.deinit();

  // When
  world.initSystems();

  // Then
  try tst.expectEqual(@TypeOf(world.systems.timeline), Systems.Timeline.System);
}

test "ECS World should deinit" {
  // Given
  var world = World.init(std.testing.allocator);

  // When
  world.deinit();

  // Then
  try tst.expectEqual(world.entity_id, 1);
}

test "ECS World should get next entity" {
  // Given
  var world = World.init(std.testing.allocator);
  defer world.deinit();

  // When
  const id = world.entityNext();
  const id2 = world.entityNext();

  // Then
  try tst.expectEqual(id, 1);
  try tst.expectEqual(id2, 2);
}

test "ECS World should add entity" {
  // Given
  var world = World.init(std.testing.allocator);
  defer world.deinit();

  // When
  const entity = world.entity("test");
  const entity2 = world.entity("test");

  // Then
  try tst.expectEqual(world.entities.count(), 1);
  try tst.expectEqual(entity.id, 1);
  try tst.expectEqual(entity2.id, 1);
  try tst.expectEqual(entity.parent_id, 0);
  try tst.expectEqual(entity2.parent_id, 0);
  try tst.expectEqual(entity.world, &world);
  try tst.expectEqual(entity2.world, &world);
}

test "ECS World should render" {
  // Given
  var world = World.init(std.testing.allocator);
  world.initSystems();
  defer world.deinit();

  // When
  const result = world.render();

  // Then
  try tst.expectEqual(result, true);
}

test "ECS World should query timeline events" {
  // Given
  var world = World.init(std.testing.allocator);
  defer world.deinit();

  _ = world.entity("timeline").timeline_init();
  _ = world.entity("test").event(.{ .start = 0, .end = 1 });

  // When
  const result = world.query(Components.TimelineEvent.Query, &world.components.timelineevent, .{ .timeline_id = .{ .eq = 1 } }, &.{.end_desc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(result.len, 1);
}

test "ECS should convert to lower case" {
  // Given
  const str = "TEST";

  // When
  const result = toLower(str);

  // Then
  try tst.expectEqualStrings(result, "test");
  try tst.expectEqual(result[result.len], 0);
}

test "ECS should match various comparison types" {
  // Given
  const TestCase = struct {
    desc: []const u8,
    actual: i32,
    cond: FieldFilter(i32),
    expected: bool,
  };

  const cases = [_]TestCase{
    .{ .desc = "eq pass", .actual = 42, .cond = .{ .eq = 42 }, .expected = true },
    .{ .desc = "eq fail", .actual = 41, .cond = .{ .eq = 42 }, .expected = false },
    .{ .desc = "lt pass", .actual = 10, .cond = .{ .lt = 20 }, .expected = true },
    .{ .desc = "gt fail", .actual = 10, .cond = .{ .gt = 20 }, .expected = false },
  };

  // When & Then
  for (cases) |c| {
    try tst.expectEqual(matchField(i32, c.actual, c.cond), c.expected);
  }
}
test "ECS should match string comparison types" {
  // Given
  const TestCase = struct {
    desc: []const u8,
    actual: []const u8,
    cond: FieldFilter([]const u8),
    expected: bool,
  };

  const cases = [_]TestCase{
    .{ .desc = "eq pass", .actual = "test", .cond = .{ .eq = "test" }, .expected = true },
    .{ .desc = "eq fail", .actual = "test", .cond = .{ .eq = "not_test" }, .expected = false },
  };

  // When & Then
  for (cases) |c| {
    try tst.expectEqual(matchField([]const u8, c.actual, c.cond), c.expected);
  }
}
