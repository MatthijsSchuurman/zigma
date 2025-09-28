const std = @import("std");
const ecs = @import("../../ecs.zig");
const ent = @import("../../entity.zig");
const rl = ecs.raylib;

const Module = @import("module.zig").Module;

pub const Music = struct {
  path: []const u8 = "",
};

pub fn init(entity: ent.Entity, params: Music) ent.Entity {
  if (entity.world.components.music.getPtr(entity.id)) |_|
    return entity;

  const new = Module.Components.Music.Component{
    .music = rl.LoadMusicStream(@ptrCast(params.path)),
    .path = params.path,
  };

  if (new.music.ctxData == null) // Failed
    return entity;

  entity.world.components.music.put(entity.id, new) catch @panic("Failed to store music");

  return play(entity);
}

pub fn deinit(entity: ent.Entity) void {
  const existing = entity.world.components.music.getPtr(entity.id) orelse return;

  rl.UnloadMusicStream(existing.music);
}

pub fn play(entity: ent.Entity) ent.Entity {
  const existing = entity.world.components.music.getPtr(entity.id) orelse return entity;

  rl.PlayMusicStream(existing.music);
  existing.playing = true;
  return entity;
}

pub fn pause(entity: ent.Entity) ent.Entity {
  const existing = entity.world.components.music.getPtr(entity.id) orelse return entity;

  rl.PauseMusicStream(existing.music);
  existing.playing = false;
  return entity;
}

pub fn speed(entity: ent.Entity, pitch: f32) ent.Entity {
  const existing = entity.world.components.music.getPtr(entity.id) orelse return entity;

  existing.speed = pitch;
  rl.SetMusicPitch(existing.music, pitch);

  if (existing.speed <= 0.0)
    _ = pause(entity)
  else if (!existing.playing)
    _ = play(entity);

  return entity;
}

pub fn seek(entity: ent.Entity, seconds: f32) ent.Entity {
  const existing = entity.world.components.music.getPtr(entity.id) orelse return entity;

  rl.SeekMusicStream(existing.music, seconds);
  return entity;
}


// Testing
const tst = std.testing;
const zigma = @import("../../ma.zig");

test "Component should do basic music commands" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  const entity = world.entity("test");

  // When
  const result = init(entity, .{.path= "default/soundtrack.ogg"});

  // Then
  try tst.expectEqual(entity.id, result.id);
  try tst.expectEqual(entity.world, result.world);

  if (world.components.music.get(entity.id)) |music| {
    try tst.expectEqual("default/soundtrack.ogg", music.path);
    try tst.expectEqual(2, music.music.stream.channels);
    try tst.expectEqual(1, music.speed);
    try tst.expectEqual(true, music.playing);
  }
  else
    return error.TestExpectedMusic;

  // When
  _ = speed(entity, 2.0);

  // Then
  if (world.components.music.get(entity.id)) |music| {
    try tst.expectEqual("default/soundtrack.ogg", music.path);
    try tst.expectEqual(2, music.music.stream.channels);
    try tst.expectEqual(2, music.speed);
    try tst.expectEqual(true, music.playing);
  }
  else
    return error.TestExpectedMusic;

  // When
  _ = pause(entity);

  // Then
  if (world.components.music.get(entity.id)) |music| {
    try tst.expectEqual("default/soundtrack.ogg", music.path);
    try tst.expectEqual(2, music.music.stream.channels);
    try tst.expectEqual(2, music.speed);
    try tst.expectEqual(false, music.playing);
  }
  else
    return error.TestExpectedMusic;
}
