pub const Module = struct {
  pub const Entities = struct {
    pub const Color = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Color = @import("component.zig");
  };

  pub const Systems = struct {
    pub const Color = @import("system.zig");
  };
};
