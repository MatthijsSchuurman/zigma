pub const Module = struct {
  pub const Entities = struct {
    pub const Music = @import("entity.zig");
  };

  pub const Components = struct {
    pub const Music = @import("component.zig");
  };

  pub const Systems = struct {
    pub const Music = @import("system.zig");
  };
};
