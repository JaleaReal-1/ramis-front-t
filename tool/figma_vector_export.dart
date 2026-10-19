// Captures Flutter paint operations as editable geometry and real text metadata.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

String number(num n) => n.toStringAsFixed(3);
String pathData(Path path) {
  final out = StringBuffer();
  for (final metric in path.computeMetrics()) {
    if (metric.length == 0) continue;
    final count = math.max(2, (metric.length / 0.65).ceil());
    for (var i = 0; i <= count; i++) {
      final p = metric
          .getTangentForOffset(
              math.min(metric.length - 0.00001, metric.length * i / count))!
          .position;
      out.write('${i == 0 ? 'M' : 'L'}${number(p.dx)} ${number(p.dy)} ');
    }
    if (metric.isClosed) out.write('Z ');
  }
  return out.toString();
}

String hex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

class PaintExporter extends PaintingContext {
  PaintExporter(this.vectorCanvas)
      : super(ContainerLayer(), const Rect.fromLTWH(0, 0, 390, 844));
  final VectorCanvas vectorCanvas;
  @override
  Canvas get canvas => vectorCanvas;
  @override
  void paintChild(RenderObject child, Offset offset) {
    final previous = vectorCanvas.owner;
    vectorCanvas.owner = child;
    child.paint(this, offset);
    vectorCanvas.owner = previous;
  }

  @override
  void pushLayer(
      ContainerLayer layer, PaintingContextCallback painter, Offset offset,
      {Rect? childPaintBounds}) {
    vectorCanvas.save();
    if (layer is TransformLayer) {
      if (layer.transform != null) {
        vectorCanvas.transform(layer.transform!.storage);
      }
    }
    if (layer is OpacityLayer) {
      vectorCanvas.alpha *= ((layer.alpha ?? 255) / 255);
      vectorCanvas.translate(layer.offset.dx, layer.offset.dy);
    }
    if (layer is ClipRectLayer) vectorCanvas.clipRect(layer.clipRect!);
    if (layer is ClipRRectLayer) vectorCanvas.clipRRect(layer.clipRRect!);
    if (layer is ClipPathLayer) vectorCanvas.clipPath(layer.clipPath!);
    painter(this, offset);
    vectorCanvas.restore();
  }
}

class VectorCanvas implements Canvas {
  final List<Map<String, dynamic>> ops = [];
  final Map<String, Map<String, dynamic>> controls = {};
  final Set<String> unsupported = {};
  RenderObject? owner;
  Matrix4 matrix = Matrix4.identity();
  List<Map<String, dynamic>> clips = [];
  double alpha = 1;
  final List<(Matrix4, List<Map<String, dynamic>>, double)> states = [];
  List<double> affine() => [
        matrix.entry(0, 0),
        matrix.entry(1, 0),
        matrix.entry(0, 1),
        matrix.entry(1, 1),
        matrix.entry(0, 3),
        matrix.entry(1, 3)
      ];
  String? control() {
    final creator = owner?.debugCreator;
    if (creator is! DebugCreator) return null;
    Element? match;
    creator.element.visitAncestorElements((e) {
      final name = e.widget.runtimeType.toString();
      if (e.widget is ButtonStyleButton ||
          RegExp(r'^(TextField|DropdownButton<|SwitchListTile|CheckboxListTile|RadioListTile<|Card$|NavigationDestination$|Tab$)')
              .hasMatch(name)) {
        match = e;
        return false;
      }
      return true;
    });
    if (match == null) return null;
    final render = match!.findRenderObject();
    if (render is! RenderBox || !render.hasSize) return null;
    final origin = render.localToGlobal(Offset.zero),
        id = match!.hashCode.toString();
    controls[id] = {
      'id': id,
      'type': match!.widget.runtimeType.toString(),
      'x': origin.dx,
      'y': origin.dy,
      'width': render.size.width,
      'height': render.size.height
    };
    return id;
  }

  void emit(Map<String, dynamic> op) {
    if (alpha < 0.001) return;
    op['matrix'] = affine();
    op['clips'] = List.of(clips);
    op['alpha'] = alpha;
    op['owner'] = owner.runtimeType.toString();
    op['control'] = control();
    ops.add(op);
  }

  String paintAttributes(Paint paint) {
    if (paint.shader != null) unsupported.add('shader:${owner.runtimeType}');
    final color = hex(paint.color), opacity = number(paint.color.a);
    return paint.style == PaintingStyle.stroke
        ? 'fill="none" stroke="$color" stroke-opacity="$opacity" stroke-width="${number(paint.strokeWidth == 0 ? 1 : paint.strokeWidth)}" stroke-linecap="${paint.strokeCap.name}" stroke-linejoin="${paint.strokeJoin.name}"'
        : 'fill="$color" fill-opacity="$opacity"';
  }

  void shape(String svg, Paint p, {String? name}) => emit({
        'kind': 'vector',
        'svg': svg,
        'paint': paintAttributes(p),
        'name': name ?? owner.runtimeType.toString()
      });
  @override
  void save() {
    states.add((matrix.clone(), List.of(clips), alpha));
  }

  @override
  void restore() {
    final state = states.removeLast();
    matrix = state.$1;
    clips = state.$2;
    alpha = state.$3;
  }

  @override
  void restoreToCount(int count) {
    while (getSaveCount() > count) {
      restore();
    }
  }

  @override
  int getSaveCount() => states.length + 1;
  @override
  void saveLayer(Rect? bounds, Paint paint) {
    save();
    alpha *= paint.color.a;
  }

  @override
  void translate(double dx, double dy) {
    matrix.multiply(Matrix4.translationValues(dx, dy, 0));
  }

  @override
  void scale(double sx, [double? sy]) {
    matrix.multiply(Matrix4.diagonal3Values(sx, sy ?? sx, 1));
  }

  @override
  void rotate(double radians) {
    matrix.multiply(Matrix4.rotationZ(radians));
  }

  @override
  void skew(double sx, double sy) {
    final m = Matrix4.identity();
    m.setEntry(0, 1, math.tan(sx));
    m.setEntry(1, 0, math.tan(sy));
    matrix.multiply(m);
  }

  @override
  void transform(Float64List m) {
    matrix.multiply(Matrix4.fromFloat64List(m));
  }

  @override
  Float64List getTransform() => matrix.storage;
  void addClip(String svg) {
    clips = [
      ...clips,
      {'svg': svg, 'matrix': affine()}
    ];
  }

  String rectSvg(Rect r) =>
      '<rect x="${number(r.left)}" y="${number(r.top)}" width="${number(r.width)}" height="${number(r.height)}"/>';
  String rrectSvg(RRect r) => '<path d="${pathData(Path()..addRRect(r))}"/>';
  @override
  void clipRect(Rect rect,
      {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    if (clipOp != ui.ClipOp.intersect) unsupported.add('clipDifference');
    addClip(rectSvg(rect));
  }

  @override
  void clipRRect(RRect rect, {bool doAntiAlias = true}) =>
      addClip(rrectSvg(rect));
  @override
  void clipPath(Path path, {bool doAntiAlias = true}) =>
      addClip('<path d="${pathData(path)}"/>');
  @override
  void clipRSuperellipse(RSuperellipse rect, {bool doAntiAlias = true}) =>
      addClip('<path d="${pathData(Path()..addRSuperellipse(rect))}"/>');
  @override
  Rect getLocalClipBounds() =>
      const Rect.fromLTWH(-10000, -10000, 20000, 20000);
  @override
  Rect getDestinationClipBounds() => const Rect.fromLTWH(0, 0, 390, 844);
  @override
  void drawRect(Rect rect, Paint paint) => shape(rectSvg(rect), paint);
  @override
  void drawRRect(RRect rect, Paint paint) => shape(rrectSvg(rect), paint);
  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) => drawPath(
      Path.combine(PathOperation.difference, Path()..addRRect(outer),
          Path()..addRRect(inner)),
      paint);
  @override
  void drawRSuperellipse(RSuperellipse rect, Paint paint) =>
      drawPath(Path()..addRSuperellipse(rect), paint);
  @override
  void drawPath(Path path, Paint paint) => shape(
      '<path fill-rule="${path.fillType == PathFillType.evenOdd ? 'evenodd' : 'nonzero'}" d="${pathData(path)}"/>',
      paint);
  @override
  void drawCircle(Offset c, double radius, Paint paint) => shape(
      '<circle cx="${number(c.dx)}" cy="${number(c.dy)}" r="${number(radius)}"/>',
      paint);
  @override
  void drawOval(Rect r, Paint paint) => shape(
      '<ellipse cx="${number(r.center.dx)}" cy="${number(r.center.dy)}" rx="${number(r.width / 2)}" ry="${number(r.height / 2)}"/>',
      paint);
  @override
  void drawLine(Offset a, Offset b, Paint paint) => shape(
      '<path d="M${a.dx} ${a.dy}L${b.dx} ${b.dy}"/>',
      Paint.from(paint)..style = PaintingStyle.stroke);
  @override
  void drawColor(Color color, BlendMode mode) =>
      drawRect(const Rect.fromLTWH(0, 0, 390, 844), Paint()..color = color);
  @override
  void drawPaint(Paint paint) =>
      drawRect(const Rect.fromLTWH(0, 0, 390, 844), paint);
  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter,
      Paint paint) {
    final path = Path();
    if (useCenter) path.moveTo(rect.center.dx, rect.center.dy);
    path.arcTo(rect, startAngle, sweepAngle, !useCenter);
    if (useCenter) path.close();
    drawPath(path, paint);
  }

  @override
  void drawShadow(
      Path path, Color color, double elevation, bool transparentOccluder) {
    emit({
      'kind': 'shadow',
      'path': pathData(path),
      'color': hex(color),
      'opacity': color.a,
      'elevation': elevation
    });
  }

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    final o = owner;
    final InlineSpan? span = o is RenderParagraph
        ? o.text
        : o is RenderEditable
            ? o.text
            : null;
    if (span == null) {
      unsupported.add('paragraph:${o.runtimeType}');
      return;
    }
    final text = span.toPlainText();
    if (text.trim().isEmpty) return;
    final runs = <Map<String, dynamic>>[];
    var index = 0;
    void walk(InlineSpan s, TextStyle inherited) {
      final style = inherited.merge(s.style);
      if (s is TextSpan) {
        final value = s.text ?? '';
        if (value.isNotEmpty) {
          runs.add({
            'start': index,
            'end': index + value.length,
            'size': style.fontSize ?? 14,
            'weight': style.fontWeight?.value ?? 400,
            'italic': style.fontStyle == FontStyle.italic,
            'family': style.fontFamily ?? 'Roboto',
            'color': hex(style.color ?? Colors.black),
            'opacity': style.color?.a ?? 1,
            'letterSpacing': style.letterSpacing ?? 0
          });
          index += value.length;
        }
        for (final child in s.children ?? <InlineSpan>[]) {
          walk(child, style);
        }
      }
    }

    walk(span, const TextStyle(fontSize: 14));
    final metrics = paragraph.computeLineMetrics();
    final lines = <Map<String, dynamic>>[];
    for (final metric in metrics) {
      final range = paragraph.getLineBoundary(ui.TextPosition(
          offset: paragraph
              .getPositionForOffset(Offset(metric.left + 0.1, metric.baseline))
              .offset));
      lines.add({
        'start': range.start,
        'end': range.end,
        'left': metric.left,
        'width': metric.width,
        'baseline': metric.baseline,
        'ascent': metric.ascent,
        'descent': metric.descent,
        'height': metric.height
      });
    }
    emit({
      'kind': 'text',
      'text': text,
      'x': offset.dx,
      'y': offset.dy,
      'width':
          paragraph.width.isFinite ? paragraph.width : paragraph.longestLine,
      'height': paragraph.height,
      'runs': runs,
      'lines': lines,
      'ellipsis': paragraph.didExceedMaxLines
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    unsupported.add(invocation.memberName.toString());
    return null;
  }
}

Future<void> exportEditableFrame(
    RenderRepaintBoundary boundary, String name) async {
  final canvas = VectorCanvas();
  final context = PaintExporter(canvas);
  context.paintChild(boundary, Offset.zero);
  final file = File('../docs/figma_transportes/editables/$name.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode({
    'name': name,
    'width': 390,
    'height': 844,
    'ops': canvas.ops,
    'controls': canvas.controls,
    'unsupported': canvas.unsupported.toList()
  }));
}
