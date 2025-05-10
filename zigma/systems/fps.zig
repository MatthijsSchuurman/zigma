const std = @import("std");
const ecs = @import("../ecs.zig");
const rl = @cImport(@cInclude("raylib.h"));

pub const System = struct {
  world: *ecs.World,

  pub fn init(world: *ecs.World) System {
    return System{
      .world = world,
    };
  }

  pub fn update(self: *System) void {
    const screen_width = rl.GetScreenWidth();
    const screen_height = rl.GetScreenHeight();

    const timeline_entity = self.world.entity("timeline");
    if (self.world.components.timeline.get(timeline_entity.id)) |timeline| {
      const fps = rl.GetFPS();

      const pos_x: i32 = screen_width - 300;
      const pos_y: i32 = screen_height - 30;

      rl.DrawRectangle(pos_x, pos_y, 300, 30, rl.Color{.r = 128, .g = 128, .b = 128, .a = 100});

      var buffer: [64]u8 = undefined;
      const fps_text = std.fmt.bufPrintZ(&buffer, "{d:0.1}", .{fps}) catch return;
      rl.DrawText(fps_text, pos_x+20, pos_y+5, 20, rl.WHITE);
      rl.DrawText("fps", pos_x+70, pos_y+5, 20, rl.Color{.r = 128, .g = 228, .b = 128, .a = 128});

      const current_text = std.fmt.bufPrintZ(&buffer, "{d:.1}", .{timeline.timeCurrent}) catch return;
      rl.DrawText(current_text, pos_x+140, pos_y+5, 20, rl.WHITE);
      rl.DrawText("s", pos_x+180, pos_y+5, 20, rl.Color{.r = 128, .g = 228, .b = 128, .a = 128});

      const speed_text = std.fmt.bufPrintZ(&buffer, "{d:.1}", .{timeline.speed}) catch return;
      rl.DrawText(speed_text, pos_x+240, pos_y+5, 20, rl.WHITE);
      rl.DrawText("x", pos_x+270, pos_y+5, 20, rl.Color{.r = 128, .g = 228, .b = 128, .a = 128});
    }
  }
};


// Testing
const tst = std.testing;
const zigma = @import("zigma");

test "System should render update" {
  // Given
  var world = ecs.World.init(std.testing.allocator);
  defer ecs.World.deinit(&world);

  rl.SetTraceLogLevel(rl.LOG_NONE);
  rl.InitWindow(320, 200, "Test");
  defer rl.CloseWindow();

  _ = world.entity("timeline").timeline_init();
  var system = System.init(&world);

  // When
  rl.BeginDrawing();
  system.update();
  rl.EndDrawing();

  // Then
  const img = rl.LoadImageFromScreen();
  defer rl.UnloadImage(img);

  const x = 30; // Not sure why these coordinates are off, but this is based on rl.TakeScreenshot()
  const y = 285;
  const color = rl.GetImageColor(img, x, y);
  try tst.expectEqual(rl.Color{.r = 50, .g = 50, .b = 50, .a = 255}, color);
}
