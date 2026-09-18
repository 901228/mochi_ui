/// The size axis shared by every component that has one: button, close button, badge, progress.
///
/// One enum rather than one per component, so `size: .sm` means the same step everywhere and a
/// row of mixed controls can be sized together. What each step measures is up to the component's
/// own metrics.
enum MochiSize { xs, sm, md, lg }
