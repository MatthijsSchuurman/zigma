const std = @import("std");
const Object = @import("objects/base.zig").Object;

pub const Scene = struct {
  allocator: std.mem.Allocator,
  objects: std.ArrayList(Object),
  lookup: std.StringHashMap(usize),

  pub fn init(allocator: std.mem.Allocator) !Scene {
    return Scene{
      .allocator = allocator,
      .objects = try std.ArrayList(Object).init(allocator),
      .lookup = try std.StringHashMap(usize).init(allocator),
    };
  }

  pub fn deinit(self: *Scene) void {
    self.objects.deinit();
    self.lookup.deinit();
  }

  pub fn object(self: *Scene, name: []const u8) !*Object {
    try self.lookup.put(name, self.objects.items.len);
    try self.objects.append(Object{}); // Empty for now
    return &self.objects.items[self.objects.items.len - 1];
  }
};

pub var gpa: std.mem.Allocator = undefined;
var scenes = std.StringHashMap(Scene).init(std.heap.page_allocator);

pub fn get(name: []const u8) *Scene {
  if (scenes.getPtr(name)) |scene| {
    return scene;
  } else {
    var new_scene = Scene.init(gpa) catch @panic("Failed to init scene");
    scenes.put(name, new_scene) catch @panic("Failed to store scene");
    return scenes.getPtr(name).?;
  }
}
