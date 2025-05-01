const std = @import("std");
const Object = @import("../objects/object.zig").Object;

pub const TimelineScene = struct {
  duration: f32 = 10.0,
};

pub const Scene = struct {
  allocator: std.mem.Allocator,
  objects: std.ArrayList(*Object),
  objectsNames: std.StringHashMap(*Object),

  timeline: TimelineScene = .{},

  pub fn init(allocator: std.mem.Allocator) Scene {
    return Scene{
      .allocator = allocator,
      .objects = std.ArrayList(*Object).init(allocator),
      .objectsNames = std.StringHashMap(*Object).init(allocator),
    };
  }

  pub fn deinit(self: *Scene) void {
    for(self.objects.items) |obj|
      obj.deinit();

    self.objects.deinit();
    self.objectsNames.deinit();
  }

  pub fn object(self: *Scene, name: []const u8, custom: anytype) *Object{
    if (self.objectsNames.getPtr(name)) |existing_object|
      return existing_object.*;

    comptime {
      const info = @typeInfo(@TypeOf(custom));
      if (info != .Pointer) @compileError("Scene expects object to be a pointer");

      const T = info.Pointer.child;
      if (!@hasField(T, "object")) @compileError("Scene expects object to have an .object field");
    }

    self.objects.append(&custom.object)  catch unreachable;
    self.objectsNames.put(name, &custom.object) catch unreachable;

    return &custom.object;
  }

  pub fn render(self: *Scene) void {
    for(self.objects.items) |obj|
      obj.render();
  }
};
