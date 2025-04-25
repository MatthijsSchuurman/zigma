const raylib = @cImport(@cInclude("raylib.h"));

pub fn text2d(text: []const u8) void {
  raylib.DrawText(text, 700, 100, 100, raylib.Color{ .r = 0, .g = 255, .b = 255, .a = 255 });
}
