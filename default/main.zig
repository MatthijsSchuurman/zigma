const std = @import("std");
const math = @import("std").math;

const raylib = @cImport({
  @cInclude("raylib.h");
});

pub fn main() void {
  const screenWidth = 800;
  const screenHeight = 450;

  raylib.InitWindow(screenWidth, screenHeight, "Zigma");
  raylib.SetTargetFPS(200);

  var t: f32 = 0.0;

  while (!raylib.WindowShouldClose()) {
    t += 0.03;

    const bounce: i32 = @intFromFloat(math.sin(t) * 130.0);
    const y = 200 + bounce;

    raylib.BeginDrawing();
    defer raylib.EndDrawing();

    raylib.ClearBackground(raylib.RAYWHITE);
    raylib.DrawText("Hello, Zigma World!", 190, y, 20, raylib.DARKGRAY);
  }

  raylib.CloseWindow();
}
