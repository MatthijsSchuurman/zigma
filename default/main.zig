const zigma = @import("zigma");

pub fn main() !void {
  var world = zigma.init(.{.title = "Zigma demo", .width = 1920, .height = 1080});

  _ = world.entity("zigma balls")
  .text("Zigma Balls!!!")
  .position(0, 0, 0)
  .size(20, 1, 1)
  .color(100, 255, 255, 150)
  .event(.{.timeline = "timeline", .start = 0, .end = 1})
    .position(0, 0.5, 0)
    .size(1, 1, 1)
    .color(0, 255, 0, 5)
  .event(.{.start = 1, .duration = 4})
    .position(0, -0.5, 0)
    .size(10, 1, 1)
    .color(255, 0, 0, 155);


  while(zigma.render(world)){}

  zigma.deinit(world);
}
