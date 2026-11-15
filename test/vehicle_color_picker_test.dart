import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vendor/widgets/vehicle_color_picker.dart';

void main() {
  testWidgets('Custom color validates and applies an exact RGB color',
      (tester) async {
    var selected = '#111418';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
      builder: (context, update) => VehicleColorPicker(
          value: selected,
          onChanged: (color) => update(() => selected = color)),
    ))));
    await tester.tap(find.text('Custom color'));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(3));
    await tester.enterText(find.byType(TextField), '#invalid');
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Use color'))
            .onPressed,
        isNull);
    await tester.enterText(find.byType(TextField), '#c0c0c0');
    await tester.pump();
    await tester.tap(find.text('Use color'));
    await tester.pumpAndSettle();
    expect(selected, '#C0C0C0');
    expect(find.text('Custom: #C0C0C0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancel preserves the saved color and presets still work',
      (tester) async {
    var selected = '#FFFFFF';
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
      builder: (context, update) => VehicleColorPicker(
          value: selected,
          onChanged: (color) => update(() => selected = color)),
    ))));
    await tester.tap(find.text('Custom: #FFFFFF'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '#FF0000');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(selected, '#FFFFFF');
    await tester.tap(find.byWidgetPredicate((widget) =>
        widget is Semantics &&
        widget.properties.label == 'Vehicle color #2563EB'));
    await tester.pump();
    expect(selected, '#2563EB');
    expect(find.text('Custom color'), findsOneWidget);
  });
}
