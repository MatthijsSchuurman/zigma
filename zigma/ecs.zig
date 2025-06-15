const std = @import("std");
pub const raylib = @cImport({
  @cInclude("raylib.h");
  @cInclude("raymath.h");
  @cInclude("rlgl.h");

  // Redefine based on lighting.fs
  @cDefine("MAX_LIGHTS", "4");
  @cDefine("LIGHT_DIRECTIONAL", "0");
  @cDefine("LIGHT_POINT", "1");
});
const rl = raylib;

const ent = @import("entity.zig");

//Components
pub const Components = struct {
  pub const Timeline = @import("components/timeline.zig");
  pub const TimelineEvent = @import("components/timelineevent.zig");
  pub const TimelineEventProgress = @import("components/timelineeventprogress.zig");
  pub const Music = @import("components/music.zig");
  pub const World = @import("components/world.zig");

  pub const Dirty = @import("components/dirty.zig");
  pub const Camera = @import("components/camera.zig");

  pub const Spawn = @import("components/spawn.zig");
  pub const Position = @import("components/position.zig");
  pub const Rotation = @import("components/rotation.zig");
  pub const Scale = @import("components/scale.zig");
  pub const Color = @import("components/color.zig");
  pub const Edge = @import("components/edge.zig");
  pub const Hide = @import("components/hide.zig");

  pub const Shader = @import("components/shader.zig");
  pub const Light = @import("components/light.zig");
  pub const Material = @import("components/material.zig");
  pub const Model = @import("components/model.zig");
  pub const Text = @import("components/text.zig");
  pub const FPS = @import("components/fps.zig");
};

const ComponentDeclarations = std.meta.declarations(Components); // Needed to prevent: unable to resolve comptime value


//Systems
pub const Systems = struct {
  pub const Timeline = @import("systems/timeline.zig");
  pub const Music = @import("systems/music.zig");
  pub const World = @import("systems/world.zig");

  pub const Dirty = @import("systems/dirty.zig");
  pub const Camera = @import("systems/camera.zig");
  pub const Shader = @import("systems/shader.zig");
  pub const Light = @import("systems/light.zig");

  // Effects
  pub const Effects_Spawn = @import("systems/effects/spawn.zig");
  pub const Effects_Position = @import("systems/effects/position.zig");
  pub const Effects_Rotation = @import("systems/effects/rotation.zig");
  pub const Effects_Scale = @import("systems/effects/scale.zig");
  pub const Effects_Color = @import("systems/effects/color.zig");
  pub const Effects_Edge = @import("systems/effects/edge.zig");
  pub const Effects_Hide = @import("systems/effects/hide.zig");

  // Render
  pub const Render_Background = @import("systems/render/background.zig");
  pub const Render_Model = @import("systems/render/model.zig");
  pub const Render_Text = @import("systems/render/text.zig");
  pub const FPS = @import("systems/render/fps.zig");
};

const SystemDeclarations = std.meta.declarations(Systems); // Needed to prevent: unable to resolve comptime value


// World
pub const World = struct {
  allocator: std.mem.Allocator,

  entity_id: ent.EntityID = 1, // 0 is no entry
  entities: std.StringHashMap(ent.EntityID),

 components: ComponentStores(),
  systems: SystemStores(),

  pub fn init(allocator: std.mem.Allocator) World {
    var self = World{
      .allocator = allocator,
      .entities = std.StringHashMap(ent.EntityID).init(allocator),
      .components = undefined,
      .systems = undefined,
    };

    inline for (ComponentDeclarations) |declaration| {
      const T = @field(Components, declaration.name).Component;
      @field(self.components, toLower(declaration.name)) = std.AutoHashMap(ent.EntityID, T).init(allocator);
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
    var id: usize = self.entity_id;
    while (id > 0) : (id -= 1) // Bit of a blunt instrument, may wanna replace this with deinit callbacks registration
      self.entityWrap(@intCast(id)).deinit();

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
  pub fn entityNextID(self: *World) ent.EntityID {
    defer self.entity_id += 1;
    return self.entity_id;
  }

  pub fn entityNext(self: *World) ent.Entity {
    const id = self.entityNextID();
    return ent.Entity{
      .id = id,
      .world = self,
    };
  }

  pub fn entityWrap(self: *World, id: ent.EntityID) ent.Entity {
    return ent.Entity{
      .id = id,
      .world = self,
    };
  }

  pub fn entity(self: *World, name: []const u8) ent.Entity {
    if (self.entities.get(name)) |id| // Existing named entity
      return ent.Entity{
        .id = id,
        .world = self,
      };

    const id = self.entityNextID();
    self.entities.put(name, id) catch @panic("Failed to store entity mapping");
    return ent.Entity{
      .id = id,
      .world = self,
    };
  }

  pub fn entityDelete(self: *World, id: ent.EntityID) void {
    self.entityWrap(id).deinit();

    inline for (ComponentDeclarations) |declaration| {
      var components = &@field(self.components, toLower(declaration.name));
      _ = components.remove(id);
    }
  }

  // Render
  pub fn render(self: *World) bool {
    self.systems.timeline.update();
    self.systems.music.update();

    self.systems.effects_hide.update();
    self.systems.effects_position.update();
    self.systems.effects_rotation.update();
    self.systems.effects_scale.update();
    self.systems.effects_color.update();
    self.systems.effects_edge.update();
    self.systems.effects_spawn.update();

    self.systems.camera.update();
    self.systems.shader.update();
    self.systems.light.update();


    // Render
    const success = self.systems.world.render(); // Rendered sub world

    self.systems.render_background.render();

    self.systems.camera.start();
    self.systems.render_model.render();
    self.systems.camera.stop();

    self.systems.render_text.render();
    self.systems.fps.render();

    self.systems.dirty.clean();
    return success;
  }

  //Components
  pub fn query(self: *World, comptime T: type, component: *const std.AutoHashMap(ent.EntityID, T.Data), filter: T.Filter, sort: []const T.Sort) []ent.EntityID {
    var results = std.ArrayList(ent.EntityID).init(self.allocator);

    var it = component.iterator();
    while (it.next()) |entry|
      if (T.filter(entry.value_ptr.*, filter))
        results.append(entry.key_ptr.*) catch @panic("Failed to append query result");

    if (@hasDecl(T, "compare") and sort.len > 0) {
      const Context = struct {
        component: *const std.AutoHashMap(ent.EntityID, T.Data),
        sort: []const T.Sort,
      };

      const context = Context {
        .component = component,
        .sort = sort,
      };

      std.sort.heap(ent.EntityID, results.items, context, struct {
        fn lessThan(ctx: Context, a: ent.EntityID, b: ent.EntityID) bool {
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
      .type          = std.AutoHashMap(ent.EntityID, T),
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

  if (T == bool)
    return switch (cond) {
      .eq => actual == cond.eq,
      .not => actual != cond.not,
      .lt => false,
      .lte => false,
      .gt => false,
      .gte => false,
    };

  if (@typeInfo(T) == .Pointer)
    return switch (cond) {
      .eq => actual == cond.eq,
      .not => actual != cond.not,
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

pub fn expectScreenshot(key: []const u8) !void {
  const test_data_dir = ".testdata";
  const file_extension = "png";

  var path_buf: [512]u8 = undefined;
  const file_path = try std.fmt.bufPrintZ(&path_buf, "{s}/{s}.{s}", .{test_data_dir, key, file_extension});

  // Get screenshots
  const actual_screenshot = rl.LoadImageFromScreen();
  defer rl.UnloadImage(actual_screenshot);

  const expected_screenshot = rl.LoadImage(file_path);
  defer rl.UnloadImage(expected_screenshot);

  if (expected_screenshot.data == null) { // No screenshot yet
    std.fs.cwd().makeDir(test_data_dir) catch {}; //Ensure test data directory exists
    _ = rl.ExportImage(actual_screenshot, file_path);
    std.debug.print("[screenshot] saved initial: {s}\n", .{file_path});
    return;
  }

  if (expected_screenshot.width != actual_screenshot.width or expected_screenshot.height != actual_screenshot.height) {
    std.debug.print("[screenshot] size mismatch: {s}\n", .{file_path});
    return error.TestImageSizeMismatch;
  }

  var failed = false;
  for (0..@as(usize, @intCast(expected_screenshot.height))) |y_usize| {
    for (0..@as(usize, @intCast(expected_screenshot.width))) |x_usize| {
      const y: c_int = @intCast(y_usize);
      const x: c_int = @intCast(x_usize);

      const expected = rl.GetImageColor(expected_screenshot, x, y);
      const actual = rl.GetImageColor(actual_screenshot, x, y);

      if (actual.r != expected.r or actual.g != expected.g or actual.b != expected.b or actual.a != expected.a) {
        failed = true;
        //std.debug.print("[screenshot] pixel mismatch at {d}, {d}\n", .{x_usize, y_usize});
        break; // TODO: implement diff overlay
      }
    }
  }

  const fail_path = try std.fmt.bufPrintZ(&path_buf, "{s}/{s}-failed.{s}", .{test_data_dir, key, file_extension});
  if (failed) {
    _ = rl.ExportImage(actual_screenshot, fail_path);
    std.debug.print("[screenshot] saved failure: {s}\n", .{fail_path});
    return error.TestImageMismatch;
  } else {
    _ = std.fs.cwd().deleteFile(fail_path) catch |e|
      if (e != error.FileNotFound)
        return e;
  }
}

test "ECS World should init" {
  // Given
  const allocator = std.testing.allocator;

  // When
  var world = World.init(allocator);
  defer world.deinit();

  // Then
  try tst.expectEqual(1, world.entity_id);
  try tst.expectEqual(0, world.entities.count());
  try tst.expectEqual(0, world.components.timeline.count());
}

test "ECS World should init systems" {
  // Given
  const allocator = std.testing.allocator;
  var world = World.init(allocator);
  defer world.deinit();

  // When
  world.initSystems();

  // Then
  try tst.expectEqual(Systems.Timeline.System, @TypeOf(world.systems.timeline));
}

test "ECS World should deinit" {
  // Given
  var world = World.init(std.testing.allocator);

  // When
  world.deinit();

  // Then
  try tst.expectEqual(1, world.entity_id);
}

test "ECS World should get next entity" {
  // Given
  var world = World.init(std.testing.allocator);
  defer world.deinit();

  // When
  const id = world.entityNextID();
  const id2 = world.entityNextID();

  // Then
  try tst.expectEqual(1, id);
  try tst.expectEqual(2, id2);
}

test "ECS World should add entity" {
  // Given
  var world = World.init(std.testing.allocator);
  defer world.deinit();

  // When
  const entity = world.entity("test");
  const entity2 = world.entity("test");

  // Then
  try tst.expectEqual(1, world.entities.count());
  try tst.expectEqual(1, entity.id);
  try tst.expectEqual(1, entity2.id);
  try tst.expectEqual(0, entity.parent_id);
  try tst.expectEqual(0, entity2.parent_id);
  try tst.expectEqual(&world, entity.world);
  try tst.expectEqual(&world, entity2.world);
}

test "ECS World should delete entity" {
  // Given
  var world = World.init(std.testing.allocator);
  defer world.deinit();

  const entity = world.entity("test").position(1, 2, 3).scale(4, 5, 6);
  const entity2 = world.entity("test2").position(1, 2, 3).scale(4, 5, 6);

  // When
  world.entityDelete(entity.id);

  // Then
  try tst.expectEqual(1, world.components.position.count());
  try tst.expectEqual(1, world.components.scale.count());
  try tst.expectEqual(0, world.components.timeline.count());

  if (world.components.position.get(entity.id)) |_|
    return error.TestEntityNotDeleted;
  if (world.components.scale.get(entity.id)) |_|
    return error.TestEntityNotDeleted;

  if (world.components.position.get(entity2.id)) |position|
    try tst.expectEqual(Components.Position.Component{.x = 1, .y = 2, .z = 3}, position)
  else
    return error.TestEntityNotFound;

  if (world.components.scale.get(entity2.id)) |scale|
    try tst.expectEqual(Components.Scale.Component{.x = 4, .y = 5, .z = 6}, scale)
  else
    return error.TestEntityNotFound;
}

test "ECS World should render" {
  // Given
  var world = World.init(std.testing.allocator);
  world.initSystems();
  defer world.deinit();

  // When
  const result = world.render();

  // Then
  try tst.expectEqual(true, result);
}

test "ECS World should query timeline events" {
  // Given
  var world = World.init(std.testing.allocator);
  defer world.deinit();

  _ = world.entity("timeline").timeline();
  _ = world.entity("test").event(.{ .start = 0, .end = 1 });

  // When
  const result = world.query(Components.TimelineEvent.Query, &world.components.timelineevent, .{ .timeline_id = .{ .eq = 1 } }, &.{.end_desc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
}

test "ECS should convert to lower case" {
  // Given
  const str = "TEST";

  // When
  const result = toLower(str);

  // Then
  try tst.expectEqualStrings("test", result);
  try tst.expectEqual(0, result[result.len]);
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
  for (cases) |c|
    try tst.expectEqual(c.expected, matchField(i32, c.actual, c.cond));
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
  for (cases) |c|
    try tst.expectEqual(c.expected, matchField([]const u8, c.actual, c.cond));
}
