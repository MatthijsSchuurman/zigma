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


// Modules
const modules = [_]type{
  @import("modules/timeline/ecs.zig"),
  @import("modules/music/ecs.zig"),
  @import("modules/subworld/ecs.zig"),

  @import("modules/dirty/ecs.zig"),
  @import("modules/hide/ecs.zig"),

  @import("modules/model/ecs.zig"),
  @import("modules/camera/ecs.zig"),
  @import("modules/shader/ecs.zig"),
  @import("modules/light/ecs.zig"),

  @import("modules/transform/ecs.zig"),
  @import("modules/material/ecs.zig"),
  @import("modules/color/ecs.zig"),
  @import("modules/edge/ecs.zig"),

  @import("modules/spawn/ecs.zig"),

  @import("modules/background/ecs.zig"),
  @import("modules/text/ecs.zig"),
  @import("modules/fps/ecs.zig"),
};

pub const Components = LoadModules(&modules, "Components");
pub const Systems = LoadModules(&modules, "Systems");

const ComponentHashTypes = GetComponentHashTypes();
const SystemTypes = GetSystemTypes();


// World
pub const World = struct {
  allocator: std.mem.Allocator,

  entity_id: ent.EntityID = 1, // 0 is no entry
  entities: std.StringHashMap(ent.EntityID),

  components: ComponentHashTypes,
  systems: SystemTypes,

  pub fn init(allocator: std.mem.Allocator) World {
    var self = World{
      .allocator = allocator,
      .entities = std.StringHashMap(ent.EntityID).init(allocator),
      .components = undefined,
      .systems = undefined,
    };

    inline for (@typeInfo(ComponentHashTypes).@"struct".fields) |field|
      @field(self.components, toLower(field.name)) = field.type.init(allocator);

    return self;
  }

  pub fn initSystems(self: *World) void {
    inline for (@typeInfo(SystemTypes).@"struct".fields) |field| {
      @field(self.systems, toLower(field.name)) = field.type.init(self);
    }
  }

  pub fn deinit(self: *World) void {
    var id: usize = self.entity_id;
    while (id > 0) : (id -= 1) // Bit of a blunt instrument, may wanna replace this with deinit callbacks registration
      self.entityWrap(@intCast(id)).deinit();

    self.entities.deinit();

    inline for (@typeInfo(ComponentHashTypes).@"struct".fields) |field|
      @field(self.components, toLower(field.name)).deinit();

    inline for (@typeInfo(SystemTypes).@"struct".fields) |field|
      if (@hasDecl(field.type, "deinit"))
        @field(self.systems, toLower(field.name)).deinit();
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

    inline for (@typeInfo(ComponentHashTypes).@"struct".fields) |field|
      @field(self.components, toLower(field.name)).remove(id);
  }

  // Render
  pub fn render(self: *World) bool {
    self.systems.timeline.update();
    self.systems.music.update();

    self.systems.hide.update();
    self.systems.position.update();
    self.systems.rotation.update();
    self.systems.scale.update();
    self.systems.color.update();
    self.systems.edge.update();
    self.systems.spawn.update();

    self.systems.camera.update();
    self.systems.shader.update();
    self.systems.light.update();


    // Render
    const success = self.systems.subworld.render();

    self.systems.background.render();

    self.systems.camera.start();
    self.systems.model.render();
    self.systems.camera.stop();

    self.systems.text.render();
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
fn LoadModules(comptime mods: []const type, comptime ecsType: []const u8) type {
  var fields: [100]std.builtin.Type.StructField = undefined;
  var fields_count: usize = 0;

  const ecsTypeSingular = if (std.mem.eql(u8, ecsType, "Systems")) "System" else "Component";

  inline for (mods) |mod| {
    if (!@hasDecl(mod, "Module"))
      @compileError("Module struct not found for " ++ @typeName(mod));

    const M = @field(mod, "Module");
    if (!@hasDecl(M, ecsType)) // Only check Components / Systems
      continue;

    const S = @field(M, ecsType);
    inline for (@typeInfo(S).@"struct".decls) |decl| { //Module -> Components / Systems declarations
      const D = @field(S, decl.name);

      if (!@hasDecl(D, ecsTypeSingular)) // declaration must have Component / System struct
        continue;

      fields[fields_count] = .{
        .name = decl.name,
        .type = D,
        .default_value_ptr = null,
        .is_comptime = false,
        .alignment = @alignOf(D),
      };

      fields_count += 1;
    }
  }

  return @Type(.{ .@"struct" = .{
    .layout = .auto,
    .fields = fields[0..fields_count],
    .decls = &.{},
    .is_tuple = false,
  }});
}

fn GetComponentHashTypes() type {
  const components = @typeInfo(Components).@"struct";
  var fields: [components.fields.len]std.builtin.Type.StructField = undefined;

  inline for (components.fields, 0..) |field, i| {
    fields[i] = .{
      .name = toLower(field.name),
      .type = std.AutoHashMap(ent.EntityID, field.type.Component),
      .default_value_ptr = null,
      .is_comptime = false,
      .alignment = @alignOf(std.AutoHashMap(ent.EntityID, field.type.Component)),
    };
  }

  return @Type(.{ .@"struct" = .{
    .layout = .auto,
    .fields = fields[0..],
    .decls = &.{},
    .is_tuple = false,
  }});
}

fn GetSystemTypes() type {
  const systems = @typeInfo(Systems).@"struct";
  var fields: [systems.fields.len]std.builtin.Type.StructField = undefined;

  inline for (systems.fields, 0..) |field, i| {
    fields[i] = .{
      .name = toLower(field.name),
      .type = field.type.System,
      .default_value_ptr = null,
      .is_comptime = false,
      .alignment = @alignOf(field.type.System),
    };
  }

  return @Type(.{ .@"struct" = .{
    .layout = .auto,
    .fields = fields[0..],
    .decls = &.{},
    .is_tuple = false,
  }});
}

pub fn toLower(comptime s: []const u8) [:0]const u8 {
  var buf: [s.len + 1]u8 = undefined;

  @setEvalBranchQuota(10000); // Needed for comptime usage
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

  if (@typeInfo(T) == .pointer)
    return switch (cond) {
      .eq => actual == cond.eq,
      .not => actual != cond.not,
      .lt => false,
      .lte => false,
      .gt => false,
      .gte => false,
    };

  if (@typeInfo(T) == .optional)
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
