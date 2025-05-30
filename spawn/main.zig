const zigma = @import("zigma");

pub fn main() void {
  zigma.init(.{.title = "Zigma test", .width = 1920, .height = 1080, .fps = 300});
  defer zigma.deinit();

  var world = zigma.create();
  defer zigma.destroy(world);

  _ = world.entity("camera").camera(.{})
  .event(.{.duration = 60, .repeat = 10, .pattern = .PingPong, .motion = .Smooth})
    .position(-5, 0.5, 2);

  _ = world.entity("background")
  .color(25, 25, 25, 255);

  _ = world.entity("floor").model(.{.type = "plane"})
  .color(64, 64, 64, 255)
  .scale(10, 0, 10)
  .position(0, -1, 0);

  _ = world.entity("torus").model(.{.type = "torus"})
  .color(128, 128, 255, 128)
  .event(.{.duration = 60, .repeat = 15, .pattern = .PingPong, .motion = .Smooth})
    .scale(2, 2, 2)
    .rotation(0.25, 0, 1);

  _ = world.entity("torus spawn").model(.{.type = "cube"}).spawn(.{.source_model = "torus"})
  .event(.{.duration = 90, .repeat = 10, .pattern = .PongPing, .motion = .EaseIn})
    .color(128, 255, 255, 200)
    .scale(0.01, 0.01, 0.01)
    .rotation(10, 10, 10);


  while(zigma.render(world)){}
}
