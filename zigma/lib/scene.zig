const std = @import("std");
const Object = @import("../objects/base.zig").Object;

pub const Scene = struct {
  allocator: std.mem.Allocator,
  objects: std.ArrayList(*Object),
  objectsNames: std.StringHashMap(*Object),

  pub fn init(allocator: std.mem.Allocator) Scene {
    return Scene{
      .allocator = allocator,
      .objects = std.ArrayList(*Object).init(allocator),
      .objectsNames = std.StringHashMap(*Object).init(allocator),
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

  pub fn object(self: *Scene, name: []const u8) *Object {
    if (self.objectsNames.getPtr(name)) |existing_object| {
      return existing_object.*;
    }

    const new_object = self.allocator.create(Object) catch unreachable;
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
