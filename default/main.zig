const std = @import("std");
const math = @import("std").math;
const zigma = @import("zigma");

const raylib = @cImport(@cInclude("raylib.h"));

var t: f32 = 0.0;

pub fn main() !void {
  zigma.init(.{
    .title = "Zigma demo",
    .width = 1920,
    .height = 1080,
  });


  _ = (try zigma.scene("intro").object("zigma_balls"))
  .init(zigma.Objects.Text.Text2D, &zigma.Objects.Text.Text2D{
    .text = "Zigma balls!",
  })
  .setPosition(100, 100, 0)
  .setColor(255, 0, 0, 255);


  while(zigma.render("intro", draw)){}

  zigma.deinit();
}

fn draw() void {
  t += 0.03;

  const bounce: i32 = @intFromFloat(math.sin(t) * 255.0);
  const color: u8 = @intCast(math.clamp(bounce, 0, 255));
  const y = 600 + bounce;

  zigma.Effects.Background.fade(raylib.Color{ .r = 0, .g = 0, .b = 0, .a = 5 });
  raylib.DrawText("Zigma balls!", 700, y, 100, raylib.Color{ .r = color, .g = 255, .b = 255-color, .a = 255 });
}
