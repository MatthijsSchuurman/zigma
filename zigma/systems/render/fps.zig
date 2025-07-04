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
    var it = self.world.components.fps.iterator();
    if (it.next()) |_| {
      const screen_width = rl.GetScreenWidth();
      const screen_height = rl.GetScreenHeight();

      const fps = rl.GetFPS();

      const pos_x: i32 = screen_width - 300;
      const pos_y: i32 = screen_height - 30;

      rl.DrawRectangle(pos_x, pos_y, 300, 30, rl.Color{.r = 128, .g = 128, .b = 128, .a = 100});

      var buffer: [64]u8 = undefined;
      const fps_text = std.fmt.bufPrintZ(&buffer, "{d:0.1}", .{fps}) catch return;
      rl.DrawText(fps_text, pos_x+20, pos_y+5, 20, rl.WHITE);
      rl.DrawText("fps", pos_x+70, pos_y+5, 20, rl.Color{.r = 128, .g = 228, .b = 128, .a = 128});

      const timeline_entity = self.world.entity("timeline");
      if (self.world.components.timeline.getPtr(timeline_entity.id)) |timeline| {
        const current_text = std.fmt.bufPrintZ(&buffer, "{d:.1}", .{timeline.timeCurrent}) catch return;
        rl.DrawText(current_text, pos_x+140, pos_y+5, 20, rl.WHITE);
        rl.DrawText("s", pos_x+180, pos_y+5, 20, rl.Color{.r = 128, .g = 228, .b = 128, .a = 128});

        const speed_text = std.fmt.bufPrintZ(&buffer, "{d:.1}", .{timeline.speed}) catch return;
        rl.DrawText(speed_text, pos_x+240, pos_y+5, 20, rl.WHITE);
        rl.DrawText("x", pos_x+270, pos_y+5, 20, rl.Color{.r = 128, .g = 228, .b = 128, .a = 128});
      }
    }
  }
};


// Testing
const tst = std.testing;

test "System should render fps" {
  // Given
  var world = ecs.World.init(tst.allocator);
  defer world.deinit();

  var system = System.init(&world);

  _ = world.entity("timeline").timeline();
  _ = world.entity("fps").fps();

  // When
  rl.BeginDrawing(); // Ensure consistent FPS
  rl.EndDrawing();
  rl.BeginDrawing();
  rl.ClearBackground(rl.BLACK); // Wipe previous test data
  system.render();
  rl.EndDrawing();

  // Then
  try ecs.expectScreenshot("system.render.fps");
}
