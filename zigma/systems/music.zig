const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = ecs.raylib;

const EntityMusic = @import("../entity/music.zig");

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn update(self: *System) void {
    const timeline_entity = self.world.entity("timeline");
    const timeline = self.world.components.timeline.getPtr(timeline_entity.id) orelse return;

    var it = self.world.components.music.iterator();
    while (it.next()) |entry| {
      const id = entry.key_ptr.*;
      const music = entry.value_ptr.*;

      if (timeline.speed != music.speed)
        _ = EntityMusic.speed(self.world.entityWrap(id), timeline.speed);

      if (timeline.timeCurrent < 0.0) { // Before start of music
        _ = EntityMusic.pause(self.world.entityWrap(id));
      } else if (timeline.timePrevious < 0.0 and timeline.timeCurrent >= 0.0) { // (Re)Start music
        _ = EntityMusic.seek(self.world.entityWrap(id), timeline.timeCurrent);
        _ = EntityMusic.play(self.world.entityWrap(id));
      } else if (@abs(timeline.timeDelta) > 0.1) { // Sync music on big jumps
        _ = EntityMusic.seek(self.world.entityWrap(id), timeline.timeCurrent);
      }

      rl.UpdateMusicStream(music.music);
    }
  }
};


// Testing
const tst = std.testing;
const SystemTimeline = @import("timeline.zig");

test "System should update music" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);
  var system_timeline = SystemTimeline.System.init(&world);

  const timeline = world.entity("timeline").timeline();
  const entity = world.entity("music").music(.{.path = "default/soundtrack.ogg"});

  // When
  _ = timeline.timeline_offset(1.0);
  system_timeline.update();
  system.update();


  // Then
  if (world.components.music.getPtr(entity.id)) |music|
    try tst.expect(rl.GetMusicTimePlayed(music.music) > 0)
  else
    return error.TestExpectedMusic;
}
