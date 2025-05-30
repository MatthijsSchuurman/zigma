const zigma = @import("zigma");

pub fn main() void {
  zigma.init(.{.title = "Zigma test", .width = 1920, .height = 1080, .fps = 30});
  defer zigma.deinit();

  var world = zigma.create();
  defer zigma.destroy(world);

  _ = world.entity("camera").camera(.{})
  .event(.{.duration = 60, .repeat = 2, .pattern = .PingPong, .motion = .Smooth})
    .position(-5, 0.5, 2);

  _ = world.entity("background")
  .color(25, 25, 25, 255);

  _ = world.entity("floor").model(.{.type = "plane"})
  .color(64, 64, 64, 255)
  .scale(10, 0, 10)
  .position(0, -1, 0);

  _ = world.entity("cube").model(.{.type = "cube"})
  .color(128, 255, 255, 200)
  .event(.{.duration = 60, .repeat = 10, .pattern = .PingPong, .motion = .Smooth})
    .rotation(1, 0, 1);

  _ = world.entity("zigma balls").text("Zigma")
  .position(-0.7, 0.8, 0)
  .scale(20, 0, 0)
  .rotation(0, 0, 0)
  .color(200, 255, 255, 150)
  .event(.{.duration = 60, .repeat = 6, .pattern = .PingPong})
    .scale(22, 0, 0);


  while(zigma.render(world)){}
}
