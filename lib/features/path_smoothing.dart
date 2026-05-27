import 'dart:math';

import 'package:flutter/widgets.dart';

Offset getSmoothedPositionAtIndex(
  List<Offset> points, {
  required int index,
  int windowSize = 3,
  List<double>? weights,
}) {
  assert(windowSize % 2 == 1, 'Window size must be odd');
  final halfWindow = windowSize ~/ 2;

  // assert(
  //   (weights == null ||
  //       (weights.reduce((a, b) => a + b) - 1.0).abs() <
  //           1e-6), // Approximately equals.
  //   "The sum of weights should equal 1. You can normalize the weights by summing them, then using: weights.map((w) => w / sum).toList()",
  // );

  final List<double> appliedWeights =
      weights ?? List.filled(windowSize, 1 / windowSize);

  assert(
    appliedWeights.length == windowSize,
    'Weights length must match window size',
  );

  Offset smoothedPoint = Offset.zero;
  for (int offset = -halfWindow; offset <= halfWindow; offset++) {
    final int neighborIndex = (index + offset).clamp(0, points.length - 1);
    final double weight = appliedWeights[offset + halfWindow];
    smoothedPoint += points[neighborIndex] * weight;
  }

  return smoothedPoint;
}

/// Generate normalized Gaussian weights for a given window size.
/// [sigma] controls the spread.
/// [sigma] 1.0 and lower has a subtle smoothing effect.
/// [sigma] windowSize / 2 has a very strong smoothing effect.
List<double> getGaussianWeights(int windowSize, {double? sigma}) {
  assert(windowSize % 2 == 1, 'Window size must be odd');
  final halfWindow = windowSize ~/ 2;
  sigma ??= windowSize / 3.0; // Default sigma

  final weights = <double>[];
  double sum = 0;
  for (int i = -halfWindow; i <= halfWindow; i++) {
    final item = exp(-(i * i) / (2 * sigma * sigma));
    weights.add(item);
    sum += item;
  }

  // Normalize so weights sum to 1
  return weights.map((w) => w / sum).toList();
}


// class StrokeData {
//   const StrokeData({
//     required this.points,
//     required this.widths,
//   });

//   static const empty = StrokeData(points: [], widths: []);

//   final List<Offset> points;
//   final List<double> widths;

//   StrokeData copyWith({
//     List<Offset>? points,
//     List<double>? widths,
//   }) {
//     return StrokeData(
//       points: points ?? this.points,
//       widths: widths ?? this.widths,
//     );
//   }
// }

/// Reduce path noise by removing points that are too close.
// StrokeData filterPoints(List<Offset> points, List<double> widths) {
//   if (points.isEmpty) return StrokeData.empty;

//   final List<Offset> filteredPts = [points.first];
//   final List<double> filteredWts = widths.isNotEmpty ? [widths.first] : [];

//   for (int i = 1; i < points.length; i++) {
//     final distance = (points[i] - filteredPts.last).distance;
//     if (distance > 0.5) {
//       filteredPts.add(points[i]);
//       if (i < widths.length) {
//         filteredWts.add(widths[i]);
//       }
//     }
//   }
//   return StrokeData(points: filteredPts, widths: filteredWts);
// }

// /// Weighted moving average filter for points.
// List<Offset> smoothPoints(List<Offset> pts) {
//   if (pts.length < 3) return pts;
//   final List<Offset> smoothed = [pts.first];
//   for (int i = 1; i < pts.length - 1; i++) {
//     final Offset p = (pts[i - 1] * 0.25) + (pts[i] * 0.5) + (pts[i + 1] * 0.25);
//     smoothed.add(p);
//   }
//   smoothed.add(pts.last);
//   return smoothed;
// }

/// Weighted moving average filter for widths.
// List<double> smoothWidths(List<double> wts) {
//   if (wts.length < 3) return wts;
//   final List<double> smoothed = [wts.first];
//   for (int i = 1; i < wts.length - 1; i++) {
//     final double w = (wts[i - 1] * 0.25) + (wts[i] * 0.5) + (wts[i + 1] * 0.25);
//     smoothed.add(w);
//   }
//   smoothed.add(wts.last);
//   return smoothed;
// }

// StrokeData filterAndSmoothStroke(List<Offset> points, List<double> widths) {
//   final filtered = filterPoints(points, widths);
//   var pts = filtered.points;
//   var wts = filtered.widths;

//   if (pts.length < 3) return filtered;

//   for (int pass = 0; pass < 2; pass++) {
//     pts = smoothPoints(pts);
//     if (wts.isNotEmpty) {
//       wts = smoothWidths(wts);
//     }
//   }
//   return StrokeData(points: pts, widths: wts);
// }

