const std = @import("std");
const ecs = @import("../../ecs.zig");
const rl = @cImport(@cInclude("raylib.h"));

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn update(self: *System) void {
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
const zigma = @import("../../ma.zig");

test "System should render update" {
  // Given
  zigma.init(.{.title = "test", .width = 320, .height = 200 });
  rl.SetTargetFPS(10);
  defer zigma.deinit();

  const world = zigma.create();
  defer zigma.destroy(world);

  _ = world.entity("background").color(255, 255, 0, 255);

  var system = System.init(world);

  // When
  rl.BeginDrawing(); // Ensure consistent FPS
  rl.EndDrawing();
  rl.BeginDrawing();
  system.update();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.background.render_update");
}
