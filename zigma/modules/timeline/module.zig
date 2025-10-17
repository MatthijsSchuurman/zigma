pub const Module = struct {
  pub const Entities = struct {
    pub const Timeline = @import("entity_timeline.zig");
    pub const TimelineEvent = @import("entity_timelineevent.zig");
    pub const TimelineEventProgress = @import("entity_timelineeventprogress.zig");
  };

  pub const Components = struct {
    pub const Timeline = @import("component_timeline.zig");
    pub const TimelineEvent = @import("component_timelineevent.zig");
    pub const TimelineEventProgress = @import("component_timelineeventprogress.zig");
  };

  pub const Systems = struct {
    pub const Timeline = @import("system_timeline.zig");
  };
};
