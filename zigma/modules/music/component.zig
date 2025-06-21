const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

pub const Component = struct {
  path: []const u8,
  music: rl.Music,
  speed: f32 = 1.0,
  playing: bool = false,
};

pub const Query = struct {
  pub const Data = Component;

  pub const Filter = struct {
    path: ?ecs.FieldFilter([]const u8) = null,
    speed: ?ecs.FieldFilter(f32) = null,
    playing: ?ecs.FieldFilter(bool) = null,
  };

  pub fn filter(self: Data, f: Filter) bool {
    if (f.path) |cond|
      if (!ecs.matchField([]const u8, self.path, cond))
        return false;

    if (f.speed) |cond|
      if (!ecs.matchField(f32, self.speed, cond))
        return false;

    if (f.playing) |cond|
      if (!ecs.matchField(bool, self.playing, cond))
        return false;

    return true;
  }

  pub const Sort = enum {
    path_asc,
    path_desc,
    speed_asc,
    speed_desc,
  };

  pub fn compare(a: Data, b: Data, sort: []const Sort) std.math.Order {
    for (sort) |field| {
      const order = switch (field) {
        .path_asc => std.mem.order(u8, a.path, b.path),
        .path_desc => std.mem.order(u8, b.path, a.path),
        .speed_asc => std.math.order(a.speed, b.speed),
        .speed_desc => std.math.order(b.speed, a.speed),
      };

      if(order != .eq) // lt/qt not further comparison needed
        return order;
    }

    return .eq;
  }

  pub fn exec(world: *ecs.World, f: Filter, sort: []const Sort) []ent.EntityID {
    return world.query(Query, &world.components.music, f, sort);
  }
};


// Testing
const tst = std.testing;
const EntityMusic = @import("entity.zig");

test "Query should filter" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = EntityMusic.init(world.entity("test1"), .{.path = "default/soundtrack.ogg"});
  _ = EntityMusic.speed(entity, 2.0);
  _ = EntityMusic.init(world.entity("test2"), .{.path = "default/soundtrack.ogg"});

  // When
  const result = Query.exec(&world, .{ .speed = .{ .gt = 1 }}, &.{.path_desc});
  defer world.allocator.free(result);

  // Then
  try tst.expectEqual(1, result.len);
  try tst.expectEqual(entity.id, result[0]);
}
