const zigma = @import("zigma");

pub fn main() !void {
  var world = zigma.init(.{.title = "Zigma demo", .width = 1920, .height = 1080});

  _ = world.entity("zigma balls")
  .com_text("Zigma Balls!!!")
  .com_position(0, 0, 0)
  .com_scale(20, 1, 1)
  .com_color(100, 255, 255, 150);

  while(zigma.render(&world)){}

  world.deinit();
}
