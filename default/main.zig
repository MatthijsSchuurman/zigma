const std = @import("std");
const math = @import("std").math;
const zigma = @import("zigma");

const rl = @cImport(@cInclude("raylib.h"));

var t: f32 = 0.0;

pub fn main() !void {
  zigma.init(.{
    .title = "Zigma demo",
    .width = 1920,
    .height = 1080,
  });

  introScene();

  zigma.scenes(.{"intro"});
  while(zigma.render(draw)){}
  zigma.deinit();
}

fn introScene() void {
  _ = zigma.object(.{
    .scene = "intro",
    .object = "zigma_balls",
    },
    zigma.Objects.Text.Text2D.init(zigma.allocator)
    .setText("Zigma balls!")
  )
  .setPosition(100, 100, 0)
  .setColor(255, 0, 0, 255);

  // zigma.effect(.{
  //   .scene = "intro",
  //   .object = "zigma_balls",
  //   .effect = zigma.Effects.Background.fade,
  //   .params = .{
  //     .colors = zigma.Object.Color{0, 0, 0, 5},
  //   },
  // });
}






fn draw() void {
  t += 0.03;

  const bounce: i32 = @intFromFloat(math.sin(t) * 255.0);
  const color: u8 = @intCast(math.clamp(bounce, 0, 255));
  const y = 600 + bounce;

  zigma.Effects.Background.fade(rl.Color{ .r = 0, .g = 0, .b = 0, .a = 5 });
  rl.DrawText("Zigma balls!", 700, y, 100, rl.Color{ .r = color, .g = 255, .b = 255-color, .a = 255 });
}
