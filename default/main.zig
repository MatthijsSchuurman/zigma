const std = @import("std");
const math = @import("std").math;
const zigma = @import("zigma");
const Object = @import("../zigma/objects/base.zig").Object;

const raylib = @cImport(@cInclude("raylib.h"));

var t: f32 = 0.0;

pub fn main() !void {
  var gpa = std.heap.GeneralPurposeAllocator(.{}){};
  const allocator = gpa.allocator();

  var zigma_balls = try allocator.create(Object);
  _ = zigma_balls.init(zigma.objects.text.Text2D, &zigma.objects.text.Text2D{
    .text = "Zigma balls!",
  });

  zigma.engine.init(.{
    .title = "Zigma demo",
    .width = 1920,
    .height = 1080,
  });

  while(zigma.engine.render(draw)){
    zigma_balls.draw();
  }

  allocator.destroy(zigma_balls);
  zigma.engine.close();
}

fn draw() void {
  t += 0.03;

  const bounce: i32 = @intFromFloat(math.sin(t) * 255.0);
  const color: u8 = @intCast(math.clamp(bounce, 0, 255));
  const y = 600 + bounce;

  zigma.effects.background.fade(raylib.Color{ .r = 0, .g = 0, .b = 0, .a = 5 });
  raylib.DrawText("Zigma balls!", 700, y, 100, raylib.Color{ .r = color, .g = 255, .b = 255-color, .a = 255 });

}
