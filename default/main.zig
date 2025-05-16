const zigma = @import("zigma");

pub fn main() void {
  zigma.init(.{.title = "Zigma demo", .width = 1920, .height = 1080});
  defer zigma.deinit();

  intro();
}

fn intro() void {
  var world = zigma.create();
  defer zigma.destroy(world);

  _ = world.entity("background")
  .color(50, 50, 50, 255);

  _ = world.entity("camera")
  .event(.{.start = 0, .end = 10, .motion = .Smooth})
    .position(-5, 0.5, 2);

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

  _ = world.entity("floor")
  .model("plane")
  .scale(10, 0, 10)
  .position(0, 0, 0);

  _ = world.entity("balls")
  .model("sphere")
  .color(100, 255, 255, 255)
  .position(0, 2, 0)
  .scale(1, 1, 1)
  .event(.{.start = 0, .duration = 10, .repeat = 20, .pattern = .PingPong, .motion = .EaseIn})
    .color(100, 255, 100, 255)
    .position(0, 0.5, 0)
    .scale(1, 0.5, 1)
  .event(.{.start = 0, .duration = 10, .repeat = 6})
    .color(100, 0, 100, 50);


  while(zigma.render(world)){}
}
