const std = @import("std");
const base = @import("../objects/base.zig");

pub const Scene = struct {
  allocator: std.mem.Allocator,
  objects: std.ArrayList(*base.Object),
  objectsNames: std.StringHashMap(*base.Object),

  pub fn init(allocator: std.mem.Allocator) Scene {
    return Scene{
      .allocator = allocator,
      .objects = std.ArrayList(*base.Object).init(allocator),
      .objectsNames = std.StringHashMap(*base.Object).init(allocator),
    };
  }

  pub fn deinit(self: *Scene) void {
    for(self.objects.items) |obj| {
      obj.custom_deinit(obj);

      self.allocator.destroy(obj);
    }

    self.objects.deinit();
    self.objectsNames.deinit();
  }

  pub fn object(self: *Scene, name: []const u8) *base.Object {
    if (self.objectsNames.getPtr(name)) |existing_object| {
      return existing_object.*;
    }

    const new_object = self.allocator.create(base.Object) catch unreachable;
    self.objects.append(new_object)  catch unreachable;
    self.objectsNames.put(name, new_object) catch unreachable;
    return new_object;
  }

  pub fn render(self: *Scene) void {
    for(self.objects.items) |obj| {
      obj.render();
    }
  }
};
