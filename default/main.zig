const zigma = @import("zigma");

pub fn main() !void {
  var world = zigma.init(.{.title = "Zigma demo", .width = 1920, .height = 1080});

  _ = world.entity("zigma balls")
  .text("Zigma Balls!!!")
  .position(0, 0, 0)
  .scale(20, 0, 0)
  .rotation(0, 0, 0)
  .color(100, 255, 255, 150)
  .event(.{.timeline = "timeline", .start = 0, .end = 2})
    .position(0, 0.5, 0)
    .scale(1, 0, 0)
    .rotation(0, 0, 1)
    .color(0, 255, 0, 5)
  .event(.{.start = 2, .duration = 5})
    .position(0, -0.5, 0)
    .scale(10, 1, 1)
    .rotation(0, 0, 2)
    .color(255, 0, 0, 155);


  while(zigma.render(world)){}

  zigma.deinit(world);
}
