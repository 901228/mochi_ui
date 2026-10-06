/// How a surface is told apart from the one it lies on.
enum MochiLayering {
  /// A 1px line and a light shadow: the web's way, and the default where there is a pointer.
  outlined,

  /// No line, and a deeper shadow: a card stands off the page the way a phone's cards do. The
  /// default on a touch theme.
  raised,
}
