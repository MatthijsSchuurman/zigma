const zigma = @import("zigma");

pub fn main() !void {
  var world = zigma.init(.{.title = "Zigma demo", .width = 1920, .height = 1080});

  _ = world.entity("background")
  .color(50, 50, 50, 10)
  .event(.{.start = 0, .end = 10, .repeat = 10, .pattern = .PingPong, .motion = .Smooth})
    .color(50, 80, 80, 10);

  _ = world.entity("zigma balls")
  .text("Zigma Balls!!!")
  .position(0, 0, 0)
  .scale(20, 0, 0)
  .rotation(0, 0, 0)
  .color(100, 255, 255, 150)
  .event(.{.start = 0, .end = 2})
    .position(0, 0.5, 0)
    .scale(1, 0, 0)
    .rotation(0, 0, 1)
    .color(0, 255, 0, 5)
  .event(.{.duration = 2})
    .position(0, -0.5, 0)
    .scale(10, 1, 1)
    .rotation(0, 0, 2)
    .color(255, 0, 0, 155)
  .event(.{.duration = 5, .repeat = 5, .pattern = .PingPong})
    .color(255, 255, 255, 255)
    .scale(20, 0, 0)
    .position(0, 0, 0);

  _ = world.entity("balls")
  .text("Balls!!!")
  .position(0, 0.8, 0)
  .scale(20, 0, 0)
  .rotation(0, 0, 0)
  .color(100, 255, 255, 50)
  .event(.{.start = 0, .duration = 5, .repeat = 5, .pattern = .PingPong, .motion = .EaseOut})
    .color(100, 255, 100, 255)
    .position(0, 0.5, 0);


  while(zigma.render(world)){}

  zigma.deinit(world);
}
