pub const Module = struct {
  pub const Entities = struct {
    pub const Model = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Model = @import("component.zig");
  };

  pub const Systems = struct {
    pub const Model = @import("system.zig");
  };
};
