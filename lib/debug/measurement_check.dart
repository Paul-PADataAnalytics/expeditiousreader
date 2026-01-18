import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class MeasurementCheckScreen extends StatefulWidget {
  const MeasurementCheckScreen({super.key});

  @override
  State<MeasurementCheckScreen> createState() => _MeasurementCheckScreenState();
}

class _MeasurementCheckScreenState extends State<MeasurementCheckScreen> {
  final GlobalKey _columnKey = GlobalKey();
  final GlobalKey _textKey = GlobalKey(); // For single line test

  String _report = 'Measuring...';

  // Test parameters
  final String _testText = "The quick brown fox jumps over the lazy dog.";
  final int _lineCount = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runMeasurement());
  }

  void _runMeasurement() {
    final settings = context.read<SettingsProvider>().settings;
    final RenderBox? columnBox =
        _columnKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? textBox =
        _textKey.currentContext?.findRenderObject() as RenderBox?;

    if (columnBox == null || textBox == null) {
      if (mounted)
        setState(() => _report = 'Error: Could not find RenderObjects');
      return;
    }

    // 1. Measure Actuals
    final double actualColumnHeight = columnBox.size.height;
    final double actualSingleFileNameHeight = textBox.size.height;

    // 2. Calculate Estimates using TextPainter
    final textPainter = TextPainter(
      text: TextSpan(
        text: _testText,
        style: TextStyle(
          fontSize: settings.traditionalFontSize,
          color: settings.textColor,
          fontFamily: settings.fontFamily,
          height: settings.lineHeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: MediaQuery.of(context).textScaler,
    );

    textPainter.layout();
    final double estimatedLineHeight = textPainter.height;
    final double estimatedsizeHeight = textPainter.size.height;

    // 3. Compare for Column
    final double expectedColumnHeight = estimatedLineHeight * _lineCount;
    final double diffTotal = actualColumnHeight - expectedColumnHeight;
    final double diffPerLine = diffTotal / _lineCount;

    final sb = StringBuffer();
    sb.writeln('=== Measurement Report ===');
    sb.writeln('Font Size: ${settings.traditionalFontSize}');
    sb.writeln('Line Height Multiplier: ${settings.lineHeight}');
    sb.writeln('TextScaler: ${MediaQuery.of(context).textScaler}');
    sb.writeln('');
    sb.writeln('--- Single Line ---');
    sb.writeln(
      'Actual Height: ${actualSingleFileNameHeight.toStringAsFixed(2)}',
    );
    sb.writeln('Painter.height: ${estimatedLineHeight.toStringAsFixed(2)}');
    sb.writeln(
      'Painter.size.height: ${estimatedsizeHeight.toStringAsFixed(2)}',
    );
    sb.writeln('');
    sb.writeln('--- Column ($_lineCount lines) ---');
    sb.writeln('Actual Height: ${actualColumnHeight.toStringAsFixed(2)}');
    sb.writeln(
      'Expected (Painter * N): ${expectedColumnHeight.toStringAsFixed(2)}',
    );
    sb.writeln('Difference Total: ${diffTotal.toStringAsFixed(2)}');
    sb.writeln(
      'Difference Per Line: ${diffPerLine > 0 ? "+" : ""}${diffPerLine.toStringAsFixed(2)}',
    );

    if (diffPerLine.abs() > 1.0) {
      sb.writeln('\nCONCLUSION: Discrepancy detected!');
      sb.writeln(
        'The widget is rendering ${diffPerLine.abs().toStringAsFixed(2)}px ${diffPerLine > 0 ? "taller" : "shorter"} per line than the painter predicts.',
      );
    } else {
      sb.writeln('\nCONCLUSION: Measurements match.');
    }

    // ignore: avoid_print
    print(sb.toString());

    if (mounted) {
      setState(() {
        _report = sb.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>().settings;
    final style = TextStyle(
      fontSize: settings.traditionalFontSize,
      color: settings.textColor,
      fontFamily: settings.fontFamily,
      height: settings.lineHeight,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Layout Debugger v2')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Text(
                  _report,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const Divider(),
              const Text('1. Control (No Settings, Row wrapped)'),
              Container(
                color: Colors.green[100],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text(_testText, key: const Key('control'))],
                ),
              ),
              const SizedBox(height: 20),
              const Text('2. User Settings (Row wrapped)'),
              Container(
                color: Colors.blue[100],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Text(_testText, style: style, key: _textKey)],
                ),
              ),
              const SizedBox(height: 20),
              const Text('3. Column Stack (User Settings)'),
              Container(
                color: Colors.red[100],
                child: Column(
                  key: _columnKey,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    _lineCount,
                    (index) => Text(_testText, style: style),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
