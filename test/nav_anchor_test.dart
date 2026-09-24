import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

const String _actionsId = 'actions';

/// A bar with an action chip in the centre island - the spot a fan could not
/// reach by counting chips from the right edge - and a fan host that opens
/// from it by id.
class _Harness extends StatefulWidget {
  const _Harness({required this.anchorId});

  final String? anchorId;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool open = false;

  void openFan() => setState(() => open = true);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ActionsFanHost(
          animation: const AlwaysStoppedAnimation<double>(1),
          open: open,
          actions: <FanAction>[
            FanAction(
              icon: testIcon('a'),
              color: const Color(0xff2196f3),
              label: 'Archive',
            ),
          ],
          closeIcon: testIcon('close'),
          closeLabel: 'Close fan',
          closeColor: const Color(0xff2196f3),
          anchorId: widget.anchorId,
          onClose: () => setState(() => open = false),
          child: const SizedBox.expand(),
        ),
        const Positioned(left: 0, right: 0, bottom: 0, child: BottomNavBar()),
      ],
    );
  }
}

NavIslandsController _controller() => NavIslandsController()
  ..override(
    left: <NavItem>[
      NavAction(label: 'Back', icon: testIcon('back'), onTap: () {}),
    ],
    center: <NavItem>[
      NavAction(
        id: _actionsId,
        label: 'Actions',
        icon: testIcon('actions'),
        onTap: () {},
      ),
    ],
    right: <NavItem>[
      NavAction(label: 'Add', icon: testIcon('add'), onTap: () {}),
    ],
  );

Future<void> _open(WidgetTester tester) async {
  tester.state<_HarnessState>(find.byType(_Harness)).openFan();
  await tester.pump();
}

void main() {
  testWidgets('a chip with an id can be found where it is', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      navHost(
        controller: controller,
        child: const _Harness(anchorId: _actionsId),
      ),
    );

    final chip = tester.getRect(find.bySemanticsLabel('Actions'));
    final anchor = controller.anchorOf(_actionsId);
    expect(anchor, isNotNull);
    expect(anchor!.center.dx, moreOrLessEquals(chip.center.dx, epsilon: 0.5));
    expect(anchor.center.dy, moreOrLessEquals(chip.center.dy, epsilon: 0.5));
  });

  testWidgets('the fan opens from a centre chip found by its id', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      navHost(
        controller: controller,
        child: const _Harness(anchorId: _actionsId),
      ),
    );
    final chip = tester.getRect(find.bySemanticsLabel('Actions'));

    await _open(tester);

    // The close button takes the chip's exact spot.
    final close = tester.getRect(find.bySemanticsLabel('Close fan'));
    expect(close.center.dx, moreOrLessEquals(chip.center.dx, epsilon: 0.5));
    expect(close.center.dy, moreOrLessEquals(chip.center.dy, epsilon: 0.5));
  });

  testWidgets('the fan finds a chip that has just slid in', (tester) async {
    // A page arriving: the bar starts empty and the islands slide and fade
    // in. The fade moves its layer without repainting the chips, so a
    // position taken while painting was left at the start of the slide.
    final controller = NavIslandsController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      navHost(
        controller: controller,
        child: const _Harness(anchorId: _actionsId),
      ),
    );
    final layout = _controller();
    controller.override(
      left: layout.islands.left,
      center: layout.islands.center,
      right: layout.islands.right,
    );
    layout.dispose();
    await tester.pumpAndSettle();
    final chip = tester.getRect(find.bySemanticsLabel('Actions'));

    await _open(tester);

    final close = tester.getRect(find.bySemanticsLabel('Close fan'));
    expect(close.center.dx, moreOrLessEquals(chip.center.dx, epsilon: 0.5));
    expect(close.center.dy, moreOrLessEquals(chip.center.dy, epsilon: 0.5));
  });

  testWidgets('labels run towards the middle: left of a centre chip', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      navHost(
        controller: controller,
        child: const _Harness(anchorId: _actionsId),
      ),
    );

    await _open(tester);

    final close = tester.getRect(find.bySemanticsLabel('Close fan'));
    expect(tester.getCenter(find.text('Archive')).dx, lessThan(close.left));
  });

  testWidgets('labels run towards the middle: right of a chip on the left', (
    tester,
  ) async {
    const leftId = 'left';
    final controller = NavIslandsController()
      ..override(
        left: <NavItem>[
          NavAction(
            id: leftId,
            label: 'Left',
            icon: testIcon('left'),
            onTap: () {},
          ),
        ],
        center: <NavItem>[
          NavAction(label: 'Actions', icon: testIcon('actions'), onTap: () {}),
        ],
      );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      navHost(
        controller: controller,
        child: const _Harness(anchorId: leftId),
      ),
    );
    final chip = tester.getRect(find.bySemanticsLabel('Left'));

    await _open(tester);

    final close = tester.getRect(find.bySemanticsLabel('Close fan'));
    expect(close.center.dx, moreOrLessEquals(chip.center.dx, epsilon: 0.5));
    // Mirrored: the label would otherwise run off the left edge.
    expect(tester.getCenter(find.text('Archive')).dx, greaterThan(close.right));
    expect(tester.getRect(find.text('Archive')).left, greaterThan(0));
  });

  testWidgets('without a chip to find, the fan falls back to the right edge', (
    tester,
  ) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      navHost(
        controller: controller,
        child: const _Harness(anchorId: 'no-such-chip'),
      ),
    );
    final centreChip = tester.getRect(find.bySemanticsLabel('Actions'));

    await _open(tester);

    final close = tester.getRect(find.bySemanticsLabel('Close fan'));
    expect(close.center.dx, greaterThan(centreChip.right));
  });

  testWidgets('a chip that leaves the bar is forgotten', (tester) async {
    final controller = _controller();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      navHost(
        controller: controller,
        child: const _Harness(anchorId: _actionsId),
      ),
    );
    expect(controller.anchorOf(_actionsId), isNotNull);

    controller.reset();
    await tester.pumpAndSettle();

    expect(controller.anchorOf(_actionsId), isNull);
  });
}
