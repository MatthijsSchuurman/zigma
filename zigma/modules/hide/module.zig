pub const Module = struct {
  pub const Entities = struct {
    pub const Hide = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Hide = @import("component.zig");
  };

  pub const Systems = struct {
    pub const Hide = @import("system.zig");
  };
};
