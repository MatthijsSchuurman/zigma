const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = ecs.raylib;

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn render(self: *System) void {
    const background_entity = self.world.entity("background");
    if (self.world.components.color.get(background_entity.id)) |color| {
      if (color.a == 0) { // No wipe
      } else if (color.a == 255) { // Full wipe
        rl.ClearBackground(rl.Color{.r = color.r, .g = color.g, .b = color.b, .a = color.a});
      } else { // Fade wipe
        rl.DrawRectangle(0, 0, rl.GetScreenWidth(), rl.GetScreenHeight(), rl.Color{.r = color.r, .g = color.g, .b = color.b, .a = color.a});
      }
    }
  }
};


// Testing
const tst = std.testing;

test "System should render background" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);

  _ = world.entity("background").color(255, 255, 0, 255);

  // When
  rl.BeginDrawing();
  rl.ClearBackground(rl.BLACK); // Wipe previous test data
  system.render();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.render.background");
}
