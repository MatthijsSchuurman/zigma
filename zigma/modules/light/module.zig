pub const Module = struct {
  pub const Entities = struct {
    pub const Light = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Light = @import("component.zig");
  };

  pub const Systems = struct {
    pub const Light = @import("system.zig");
  };
};
