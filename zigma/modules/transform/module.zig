pub const Module = struct {
  pub const Entities = struct {
    pub const Position = @import("entity_position.zig");
    pub const Scale = @import("entity_scale.zig");
    pub const Rotation = @import("entity_rotation.zig");
  };

  pub const Components = struct {
    pub const Position = @import("component_position.zig");
    pub const Scale = @import("component_scale.zig");
    pub const Rotation = @import("component_rotation.zig");
  };

  pub const Systems = struct {
    pub const Position = @import("system_position.zig");
    pub const Scale = @import("system_scale.zig");
    pub const Rotation = @import("system_rotation.zig");
  };
};
