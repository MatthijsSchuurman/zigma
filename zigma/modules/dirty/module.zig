pub const Module = struct {
  pub const Entities = struct {
    pub const Dirty = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Dirty = @import("component.zig");
  };

  pub const Systems = struct {
    pub const Dirty = @import("system.zig");
  };
};
