const raylib = @cImport(@cInclude("raylib.h"));

pub fn clear(color: raylib.Color) void {
  raylib.ClearBackground(color);
}

pub fn fade(color: raylib.Color) void {
  raylib.DrawRectangle(0, 0, raylib.GetScreenWidth(), raylib.GetScreenHeight(), color);
}
