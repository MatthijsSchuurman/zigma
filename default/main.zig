const zigma = @import("zigma");

pub fn main() void {
  zigma.init(.{.title = "Zigma demo", .width = 1920, .height = 1080});
  defer zigma.deinit();

  intro();
}

fn intro() void {
  var world = zigma.create();
  defer zigma.destroy(world);

  _ = world.entity("light shader").shader(.{.type = "lighting"})
    .color(255, 255, 255, 255);

  _ = world.entity("camera").camera(.{})
  .event(.{.duration = 5, .motion = .EaseIn})
    .position(-5, 3, 2)
  .event(.{.duration = 10, .motion = .EaseOut})
    .position(-10, 0.0, -2);

  _ = world.entity("light").light(.{.type = .Point})
  .color(0, 0, 255, 255)
  .event(.{.end = 10, .motion = .Smooth})
    .color(255, 0, 0, 255);


  _ = world.entity("background")
  .color(50, 50, 50, 255)
  .event(.{.end = 10, .motion = .Linear})
    .color(25, 25, 25, 255);


  _ = world.entity("floor material").material(.{.shader = "light shader"})
  .color(200, 200, 200, 255);
  _ = world.entity("floor").model(.{.type = "plane", .material = "floor material"})
  .scale(10, 0, 10)
  .position(0, 0, 0);

  _ = world.entity("ball material").material(.{.shader = "light shader"});
  _ = world.entity("ball 1").model(.{.type = "sphere", .material = "ball material"})
  .color(100, 255, 255, 255)
  .position(0, 2, 0)
  .scale(1, 1, 1)
  .event(.{.duration = 20, .repeat = 20, .pattern = .PingPong, .motion = .EaseIn})
    .color(100, 255, 100, 150)
    .position(0, 0.5, 0)
    .scale(1, 0.5, 1);

  _ = world.entity("ball 2").model(.{.type = "sphere", .material = "ball material"})
  .color(100, 255, 100, 255)
  .position(2, 0.5, 1)
  .scale(1, 0.5, 1)
  .event(.{.duration = 20, .repeat = 20, .pattern = .PingPong, .motion = .EaseOut})
    .color(255, 255, 255, 150)
    .position(2, 2, 1)
    .scale(1, 1, 1);

  _ = world.entity("zigma balls").text("Zigma Balls!!!")
  .position(0, 0, 0)
  .scale(20, 0, 0)
  .rotation(0, 0, 0)
  .color(100, 255, 255, 150)
  .event(.{.end = 2})
    .position(0, 0.5, 0)
    .scale(1, 0, 0)
    .rotation(0, 0, 1)
    .color(0, 255, 0, 5)
  .event(.{.duration = 2})
    .position(0, -0.5, 0)
    .scale(10, 1, 1)
    .rotation(0, 0, 2)
    .color(255, 0, 0, 155)
  .event(.{.duration = 5, .repeat = 6, .pattern = .PingPong})
    .color(255, 255, 255, 255)
    .scale(20, 0, 0)
    .position(0, 0, 0);


  while(zigma.render(world)){}
}
