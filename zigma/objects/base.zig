const std = @import("std");

pub const Position = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub const Scale = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub const Rotation = struct {
  x: f32,
  y: f32,
  z: f32,
};

pub const max_colors = 2;
pub const Color = struct {
  r: u8,
  g: u8,
  b: u8,
  a: u8,
};

pub const Object = struct {
  position: Position,
  scale: Scale,
  rotation: Rotation,
  colors: [max_colors]Color,

  custom: *const anyopaque,
  custom_render: *const fn(*const Object) void,

  pub fn init(self: *Object, comptime T: type, custom: *const T) *Object {
    self.position = .{ .x = 0, .y = 0, .z = 0 };
    self.scale = .{ .x = 1, .y = 1, .z = 1 };
    self.rotation = .{ .x = 0, .y = 0, .z = 0 };
    self.colors = [_]Color{
        Color{ .r = 255, .g = 255, .b = 255, .a = 255 },
        Color{ .r = 0, .g = 0, .b = 0, .a = 255 },
    };

    self.custom = custom;
    self.custom_render = &T.render;
    return self;
  }

  pub fn setPosition(self: *Object, x: f32, y: f32, z: f32) *Object {
    self.position = Position{ .x = x, .y = y, .z = z };
    return self;
  }

  pub fn setScale(self: *Object, x: f32, y: f32, z: f32) *Object {
    self.scale = Scale{ .x = x, .y = y, .z = z };
    return self;
  }

  pub fn setRotation(self: *Object, x: f32, y: f32, z: f32) *Object {
    self.rotation = Rotation{ .x = x, .y = y, .z = z };
    return self;
  }

  pub fn setColor(self: *Object, r: u8, g: u8, b: u8, a: u8) *Object {
    self.colors[0] = Color{ .r = r, .g = g, .b = b, .a = a };
    return self;
  }
  pub fn setColors(self: *Object, list: []const Color) *Object {
    const count = @min(list.len, max_colors);
    for (list[0..count], 0..) |c, i| {
      self.colors[i] = c;
    }

    return self;
  }

  pub fn render(self: *Object) void {
    self.custom_render(self);
  }
};
