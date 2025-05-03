const zigma = @import("zigma");

pub fn main() !void {
  var world = zigma.init(.{.title = "Zigma demo", .width = 1920, .height = 1080});

  _ = world.entity("zigma balls")
  .text("Zigma Balls!!!")
  .position(0, 0, 0)
  .scale(20, 1, 1)
  .color(100, 255, 255, 150);

  while(zigma.render(&world)){}

  world.deinit();
}
