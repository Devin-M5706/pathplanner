import 'package:file/memory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pathplanner/path/choreo_path.dart';
import 'package:pathplanner/trajectory/trajectory.dart';
import 'package:pathplanner/util/prefs.dart';
import 'package:pathplanner/util/wpimath/geometry.dart';
import 'package:pathplanner/util/wpimath/kinematics.dart';
import 'package:pathplanner/widgets/editor/path_painter.dart';
import 'package:pathplanner/widgets/editor/split_choreo_path_editor.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/choreo_path_tree.dart';
import 'package:pathplanner/widgets/field_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:undo/undo.dart';

void main() {
  late ChoreoPath path;
  late SharedPreferences prefs;
  late ChangeStack undoStack;

  setUp(() async {
    path = ChoreoPath(
      name: 'test',
      trajectory: PathPlannerTrajectory.fromStates([
        TrajectoryState.pregen(0.0, const ChassisSpeeds(),
            const Pose2d(Translation2d(), Rotation2d())),
        TrajectoryState.pregen(1.0, const ChassisSpeeds(),
            const Pose2d(Translation2d(), Rotation2d())),
      ]),
      fs: MemoryFileSystem(),
      choreoDir: '/choreo',
      eventMarkerTimes: [0.5],
    );
    undoStack = ChangeStack();
    SharedPreferences.setMockInitialValues({
      PrefsKeys.holonomicMode: true,
      PrefsKeys.treeOnRight: true,
      PrefsKeys.robotWidth: 1.0,
      PrefsKeys.robotLength: 1.0,
      PrefsKeys.showRobotDetails: true,
      PrefsKeys.showGrid: true,
    });
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('has painter and tree', (widgetTester) async {
    await widgetTester.binding.setSurfaceSize(const Size(1280, 720));

    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SplitChoreoPathEditor(
          prefs: prefs,
          path: path,
          fieldImage: FieldImage.official(OfficialField.crescendo),
          undoStack: undoStack,
        ),
      ),
    ));

    var painters = find.byType(CustomPaint);
    bool foundPathPainter = false;
    for (var p in widgetTester.widgetList(painters)) {
      if ((p as CustomPaint).painter is PathPainter) {
        foundPathPainter = true;
      }
    }
    expect(foundPathPainter, true);
    expect(find.byType(ChoreoPathTree), findsOneWidget);
  });

  testWidgets('swap tree side', (widgetTester) async {
    await widgetTester.binding.setSurfaceSize(const Size(1280, 720));

    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SplitChoreoPathEditor(
          prefs: prefs,
          path: path,
          fieldImage: FieldImage.official(OfficialField.crescendo),
          undoStack: undoStack,
        ),
      ),
    ));

    final swapButton = find.byTooltip('Move to Other Side');

    expect(swapButton, findsOneWidget);

    await widgetTester.tap(swapButton);
    await widgetTester.pump();

    expect(prefs.getBool(PrefsKeys.treeOnRight), false);

    await widgetTester.tap(swapButton);
    await widgetTester.pump();

    expect(prefs.getBool(PrefsKeys.treeOnRight), true);
  });

  testWidgets('change tree size', (widgetTester) async {
    await widgetTester.binding.setSurfaceSize(const Size(1280, 720));

    await widgetTester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SplitChoreoPathEditor(
          prefs: prefs,
          path: path,
          fieldImage: FieldImage.official(OfficialField.crescendo),
          undoStack: undoStack,
        ),
      ),
    ));

    await widgetTester.dragFrom(
        widgetTester.getCenter(find.byType(SplitChoreoPathEditor)),
        const Offset(-100, 0));

    await widgetTester.pump(const Duration(seconds: 1));

    expect(prefs.getDouble(PrefsKeys.editorTreeWeight), closeTo(0.58, 0.01));

    await widgetTester.tap(find.byTooltip('Move to Other Side'));
    await widgetTester.pump();

    await widgetTester.dragFrom(
        widgetTester.getCenter(find.byType(SplitChoreoPathEditor)) +
            const Offset(100, 0),
        const Offset(-100, 0));

    await widgetTester.pump(const Duration(seconds: 1));

    expect(prefs.getDouble(PrefsKeys.editorTreeWeight), closeTo(0.5, 0.01));
  });
}
