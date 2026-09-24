import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_islands_controller.dart';

/// Registers [child] with [controller] under [id], so an `ActionsFanHost` can
/// open its fan from exactly where the chip is.
///
/// The chip itself is registered, not a position it once had: its position is
/// worked out when the fan asks for it, through the transforms of the islands
/// as they are at that moment. A position recorded while painting went stale —
/// an island entering fades in, and a fading layer is moved without its chips
/// being repainted, so the last painted spot was where the slide started.
class NavAnchorReporter extends SingleChildRenderObjectWidget {
  /// Creates the reporter.
  const NavAnchorReporter({
    required this.id,
    required this.controller,
    required super.child,
    super.key,
  });

  /// The item id the chip is registered under.
  final String id;

  /// Where the chip is registered.
  final NavIslandsController controller;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderNavAnchor(id, controller);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderNavAnchor renderObject,
  ) {
    renderObject
      ..id = id
      ..controller = controller;
  }
}

/// The render object behind [NavAnchorReporter]: registered with the
/// controller while it is attached to the tree.
class RenderNavAnchor extends RenderProxyBox {
  /// Creates the render object for [_id], registered with [_controller].
  RenderNavAnchor(this._id, this._controller);

  String _id;
  set id(String value) {
    if (value == _id) return;
    // The chip now stands for another item.
    _controller.unregisterAnchor(_id, this);
    _id = value;
    if (attached) _controller.registerAnchor(_id, this);
  }

  NavIslandsController _controller;
  set controller(NavIslandsController value) {
    if (identical(value, _controller)) return;
    _controller.unregisterAnchor(_id, this);
    _controller = value;
    if (attached) _controller.registerAnchor(_id, this);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller.registerAnchor(_id, this);
  }

  @override
  void detach() {
    _controller.unregisterAnchor(_id, this);
    super.detach();
  }
}
