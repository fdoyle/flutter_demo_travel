//an implementation of CSS grid in flutter

import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SparseList<T> {
  int len = 0;
  LinkedHashMap<int, T> collection = LinkedHashMap();
  T Function(int x) builder;

  SparseList(this.builder);

  T get(int index) {
    collection.putIfAbsent(index, () => this.builder(index));
    len = max(index, len);
    return collection[index];
  }

  int get length {
    return len + 1;
  }
}

/*
* V1 assumptions:
* grid always expands down (adding rows, never columns)
* all auto-placed items have a size of 1 row and 1 column
* all fixed items have a definite position and size
* items will always fill assigned cell
* no grid gap
* items can't set position to bottom of grid (so no row end of -1 or whatever)
* */
class Grid extends MultiChildRenderObjectWidget {
  List<TrackConstraint> rowConstraints;
  List<TrackConstraint> columnConstraints;
  TrackConstraint rowAutoConstraint = Auto();
  double gapSize;

  Grid(
      {Key key,
      List<Widget> children = const <Widget>[],
      this.rowConstraints = const <TrackConstraint>[],
      this.rowAutoConstraint,
      this.columnConstraints = const <TrackConstraint>[],
      this.gapSize = 0})
      : super(key: key, children: children);

  @protected
  TextDirection getEffectiveTextDirection(BuildContext context) {
    return TextDirection.ltr;
  }

  @override
  RenderGrid createRenderObject(BuildContext context) {
    return RenderGrid(
        rowConstraints, columnConstraints, rowAutoConstraint, gapSize);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderGrid renderObject) {
    renderObject
      ..rowConstraints = rowConstraints
      ..columnConstraints = columnConstraints;
  }
}

class TrackConstraint {}

class Fixed implements TrackConstraint {
  double size = 0;

  Fixed(this.size);

  @override
  String toString() {
    return 'Fixed{size: $size}';
  }
}

class Fraction implements TrackConstraint {
  double fraction;

  Fraction({this.fraction = 1}) {
    assert(fraction > 0);
  }

  @override
  String toString() {
    return 'Fraction{fraction: $fraction}';
  }
}

class Percent implements TrackConstraint {
  double percent;

  Percent(this.percent);

  @override
  String toString() {
    return 'Percent{percent: $percent}';
  }
}

class Auto implements TrackConstraint {
  @override
  String toString() {
    return 'Auto{}';
  }
}

class Track {
  TrackConstraint constraint;
  Set<GridElement> cellsInTrack = Set();

  int position;

  double autoSize = 0;
  double fractionSize = 0;

  Track(this.constraint, this.position);

  void addElement(GridElement element) {
    cellsInTrack.add(element);
  }

  double getFixedSize() {
    if (constraint is Fixed) {
      return (constraint as Fixed).size;
    } else {
      return 0;
    }
  }

  double getFraction() {
    if (constraint is Fraction) {
      return (constraint as Fraction).fraction;
    } else {
      return 0;
    }
  }

  void calculateFractionSize(double remainingSpace, double fractionSum) {
    assert(fractionSum >= getFraction());
    if (getFraction() == 0) {
      fractionSize = 0;
    } else {
      fractionSize = getFraction() / fractionSum * remainingSpace;
    }
  }

  double getSize() {
    return getFixedSize() + autoSize + fractionSize;
  }

  @override
  String toString() {
    return 'Track{constraint: $constraint, position: $position}';
  }
}

class GridElement {
  SplayTreeSet<Track> _rows =
      SplayTreeSet((key1, key2) => key1.position.compareTo(key2.position));
  SplayTreeSet<Track> _columns =
      SplayTreeSet((key1, key2) => key1.position.compareTo(key2.position));
  int autoRowCount = 0;
  int autoColumnCount = 0;
  double fixedWidthOfColumns = 0;
  double fixedHeightOfRows = 0;
  RenderBox renderBox;
  GridParentData parentData;

  GridElement(this.renderBox, this.parentData);

  double _minIntrinsicWidth;
  double _minIntrinsicHeight;

  double minWidth;
  double minHeight;

  GridElement.fake(
      {Placement hStart, Placement vStart, Placement hEnd, Placement vEnd}) {
    this.parentData = GridParentData();
    parentData
      ..vStart = vStart
      ..vEnd = vEnd
      ..hStart = hStart
      ..hEnd = hEnd;
  }

  void addToRow(Track track) {
    _rows.add(track);
    TrackConstraint c = track.constraint;
    if (c is Auto) {
      autoRowCount++;
    }
    if (c is Fixed) {
      fixedHeightOfRows += c.size;
    }
  }

  void addToColumn(Track track) {
    _columns.add(track);
    TrackConstraint c = track.constraint;
    if (c is Auto) {
      autoColumnCount++;
    }
    if (c is Fixed) {
      fixedWidthOfColumns += c.size;
    }
  }

  Track getFirstRow() => _rows.first;

  Track getLastRow() => _rows.last;

  Track getFirstColumn() => _columns.first;

  Track getLastColumn() => _columns.last;

  //to be called before flex width is assigned
  void calculateMinWidth() {
    _minIntrinsicWidth = renderBox.getMinIntrinsicWidth(double.infinity);
    minWidth = max(
        renderBox.getMinIntrinsicWidth(double.infinity), fixedWidthOfColumns);
  }

  //to be called after flex width is assigned
  void calculateMinHeight() {
    double widthOfColumns = 0;
    for (Track t in _columns) {
      widthOfColumns += t.getSize();
    }

    _minIntrinsicHeight = renderBox.getMinIntrinsicHeight(widthOfColumns);

    minHeight = max(_minIntrinsicHeight, fixedHeightOfRows);
  }

//  void calculateMinSize() {
//    if (_minIntrinsicWidth == null || _minIntrinsicHeight == null) {
//      _minIntrinsicWidth = renderBox.getMinIntrinsicWidth(double.infinity);
//
//      minWidth = max(
//          renderBox.getMinIntrinsicWidth(double.infinity), fixedWidthOfColumns);
//
//      _minIntrinsicHeight = renderBox.getMinIntrinsicHeight(minWidth);
//      minHeight =
//          max(_minIntrinsicHeight, fixedHeightOfRows);
//    }
//  }

  double getMinIntrinsicWidth(double height) =>
      renderBox.getMinIntrinsicHeight(height);

  double getMaxIntrinsicWidth(double height) =>
      renderBox.getMinIntrinsicHeight(height);

  double getMinIntrinsicHeight(double width) =>
      renderBox.getMinIntrinsicHeight(width);

  double getMaxIntrinsicHeight(double width) =>
      renderBox.getMinIntrinsicHeight(width);

  void finalize() {
    //make final calculations
  }
}

//this class is zero indexed
class GridArray {
  var occupiedCells = <bool>[];
  List<TrackConstraint> columnConstraints;
  List<TrackConstraint> rowConstraints;
  TrackConstraint rowAutoConstraint;
  Map<RenderBox, GridElement> gridElements = Map();

  SparseList<Track> columnTracks;
  SparseList<Track> rowTracks;

  Map<Track, double> trackStart = Map(); // used for both columns and rows
  Map<Track, double> trackEnd = Map();

  List<Track> rows = [];
  List<Track> columns = [];
  int lastFilledIndex = -1;

  double columnFractionSum = 0;
  double rowFractionSum = 0;

  double fixedWidth = 0;
  double fixedHeight = 0;

  double gapSize = 0;

  bool solved = false;

  List<RenderBox> children = [];
  double maxWidth = -1;
  double maxHeight = -1;

  GridArray(this.rowConstraints, this.columnConstraints, this.rowAutoConstraint,
      this.gapSize) {
    columnTracks =
        SparseList((column) => Track(this.columnConstraints[column], column));
    rowTracks = SparseList((row) {
      if (rowConstraints.length > row) {
        return Track(this.rowConstraints[row], row);
      } else {
        return Track(rowAutoConstraint, row);
      }
    });
  }

  void clear() {
    occupiedCells = [];
    lastFilledIndex = -1;
  }

  bool hasAddedChildren = false;

  void solve(List<RenderBox> children, double maxWidth, double maxHeight) {
    if(ListEquality().equals(this.children, children) && this.maxWidth == maxWidth && this.maxHeight == maxHeight){
      return;
    }
    this.children = children;
    this.maxWidth = maxWidth;
    this.maxHeight = maxHeight;

    hasAddedChildren = true;
    var positionedItems = <RenderBox>[];
    var automaticallyPlacedItems = <RenderBox>[];

    //filter children to fixed and unfixed
    for (RenderBox child in children) {
      print("separating fixed vs automatic");
      var parentData = child.parentData;
      if (parentData is GridParentData && parentData.specifiesPosition()) {
        positionedItems.add(child);
      } else {
        automaticallyPlacedItems.add(child);
      }
    }

    //place children
    for (RenderBox b in positionedItems) {
      GridElement element = GridElement(b, b.parentData);
      gridElements[b] = element;
      _addFixedElement(element);
    }

    for (RenderBox b in automaticallyPlacedItems) {
      GridElement element = GridElement(b, b.parentData);
      gridElements[b] = element;
      _addAutomaticallyPlacedElement(element);
    }

    //calculate fixed sizes
    columnFractionSum = 0;
    fixedWidth = 0;
    for (int i = 0; i != columnTracks.length; i++) {
      Track c = columnTracks.get(i);
      columnFractionSum += c.getFraction();
      fixedWidth += c.getFixedSize();
    }

    rowFractionSum = 0;
    fixedHeight = 0;
    for (int i = 0; i != rowTracks.length; i++) {
      Track r = rowTracks.get(i);
      rowFractionSum += r.getFraction();
      fixedHeight += r.getFixedSize();
    }

    double fullGapWidth = gapSize * (columnTracks.length - 1);
    //calculate auto sizes

    //calculate auto widths
    for (int i = 0; i != columnTracks.length; i++) {
      Track track = columnTracks.get(i);
      if (!(track.constraint is Auto)) {
        // no need to do work for non-auto tracks
        continue;
      }
      double largestMinWidth = 0;
      for (GridElement e in track.cellsInTrack) {
        e.calculateMinWidth();
        largestMinWidth = max(largestMinWidth,
            e._minIntrinsicWidth / e.autoColumnCount - e.fixedWidthOfColumns);
      }
      track.autoSize = largestMinWidth;
    }

    //calculate width fractions
    double widthRemainingForFraction;
    if (maxWidth == double.infinity) {
      widthRemainingForFraction = 0;
    } else {
      widthRemainingForFraction = maxWidth - fixedWidth - fullGapWidth;
    }

    for (int i = 0; i != columnTracks.length; i++) {
      Track t = columnTracks.get(i);
      t.calculateFractionSize(widthRemainingForFraction, columnFractionSum);
    }

    double cumulativeWidth = 0;
    print("starting width = 0");
    for (int i = 0; i != columnTracks.length; i++) {
      Track t = columnTracks.get(i);
      print("loading column $i, $t");
      trackStart[t] = cumulativeWidth;
      cumulativeWidth += t.getSize();
      trackEnd[t] = cumulativeWidth;
      cumulativeWidth += gapSize;
      print("  start ${trackStart[t]}, end ${trackEnd[t]}");
      print("  cumulative width: $cumulativeWidth");
    }

    //calculate auto heights
    for (int i = 0; i != rowTracks.length; i++) {
      Track track = rowTracks.get(i);
      if (!(track.constraint is Auto)) {
        // no need to do work for non-auto tracks
        continue;
      }
      double largestMinHeight = 0;
      for (GridElement e in track.cellsInTrack) {
        e.calculateMinHeight();
        largestMinHeight = max(largestMinHeight,
            e._minIntrinsicHeight / e.autoRowCount - e.fixedHeightOfRows);
      }
      print("track $i size = $largestMinHeight");
      track.autoSize = largestMinHeight;
    }

    //calculate height fractions
    double heightRemainingForFraction;
    if (maxHeight == double.infinity) {
      heightRemainingForFraction = 0;
    } else {
      heightRemainingForFraction = maxHeight - fixedHeight;
    }

    for (int i = 0; i != rowTracks.length; i++) {
      Track t = rowTracks.get(i);
      t.calculateFractionSize(heightRemainingForFraction, rowFractionSum);
    }

    double cumulativeHeight = 0;
    print("starting height = 0");
    for (int i = 0; i != rowTracks.length; i++) {
      Track t = rowTracks.get(i);
      print("loading row $i, $t");
      trackStart[t] = cumulativeHeight;
      cumulativeHeight += t.getSize();
      trackEnd[t] = cumulativeHeight;
      cumulativeHeight += gapSize;
      print("  start ${trackStart[t]}, end ${trackEnd[t]}");
      print("  cumulative height: $cumulativeHeight");
    }
  }

  getTrackStart(Track track) {
    return trackStart[track];
  }

  getTrackEnd(Track track) {
    return trackEnd[track];
  }

  RenderBox nextChild(RenderBox box) {
    return (box.parentData as GridParentData).nextSibling;
  }

  void _addFixedElement(GridElement element) {
    Placement vStart = element.parentData.vStart;
    Placement vEnd = element.parentData.vEnd;
    Placement hStart = element.parentData.hStart;
    Placement hEnd = element.parentData.hEnd;
    assert(vStart != null);
    assert(vEnd != null);
    assert(hStart != null);
    assert(hEnd != null);

    assert(hStart is Line);
    if (hEnd is Line) {
      assert(hEnd.line > (hStart as Line).line);
    } else if (hEnd is Span) {}
    assert(vStart is Line && vStart.line > 0);
    if (vEnd is Line) {
      assert(vEnd.line > (vStart as Line).line);
    }

    int x = (hStart as Line).line - 1; //line 1 is far left, so track 0
    int y = (vStart as Line).line - 1;
    int width;
    if (hEnd is Line) {
      width = hEnd.line - x - 1;
    } else if (hEnd is Span) {
      width = hEnd.span;
    } else {
      width = 1;
    }

    int height;
    if (vEnd is Line) {
      height = vEnd.line - x - 1;
    } else if (vEnd is Span) {
      height = vEnd.span;
    } else {
      height = 1;
    }

    int columnCount =
        columnConstraints.length; //columns are always fixed (for now)
    int index = (y + height - 1) * columnCount + (x + width - 1);
    int lastReferencableIndex = occupiedCells.length - 1;

    if (lastReferencableIndex < index) {
      int newCellsNeeded = index - lastReferencableIndex;
      occupiedCells.length = occupiedCells.length + newCellsNeeded;
    }
    for (int r = 0; r != height; r++) {
      int row = r + y;
      for (int c = 0; c != width; c++) {
        int column = c + x;
        int i = (row) * columnCount + column;
        occupiedCells[i] = true;
        lastFilledIndex = max(lastFilledIndex, i);
        addElementToColumn(column, element);
      }
      addElementToRow(row, element);
    }
  }

  //assumption: this will always be called after
  void _addAutomaticallyPlacedElement(GridElement element) {
    lastFilledIndex++;
    if (occupiedCells.length <= lastFilledIndex) {
      print("columnConstraints length ${columnConstraints.length}");
      occupiedCells.length += columnConstraints.length; //add another full row
    }
    print(
        "occupied cells length ${occupiedCells.length}/lastFilledIndex $lastFilledIndex");
    occupiedCells[lastFilledIndex] = true;
    int row = (lastFilledIndex / columnConstraints.length).floor();
    int column = lastFilledIndex % columnConstraints.length;
    print("Adding new item to row:$row column:$column");
    addElementToColumn(column, element);
    addElementToRow(row, element);
  }

  void addElementToRow(int row, GridElement element) {
    Track track = rowTracks.get(row);
    track.addElement(element);
    element.addToRow(track);
  }

  void addElementToColumn(int column, GridElement element) {
    Track track = columnTracks.get(column);
    track.addElement(element);
    element.addToColumn(track);
  }

  int getColumns() {
    return columnConstraints.length;
  }

  int getRows() {
    return max(rowTracks.length, rowConstraints.length);
  }

  bool isCellOccupied(int x, int y) {
    int i = (y) * columnConstraints.length + x;
    return occupiedCells[i] == true; //might be null
  }

  bool isIndexOccupied(int i) {
    return occupiedCells[i] == true; //might be null
  }

  double getFixedWidth() {
    return 200;
  }

  @override
  String toString() {
    int columnCount = columnConstraints.length;
    StringBuffer string = StringBuffer();
    int rows = (occupiedCells.length / columnCount).ceil();

    for (int r = 0; r != rows; r++) {
      StringBuffer b = StringBuffer("[");
      for (int c = 0; c != columnCount; c++) {
        int index = r * columnCount + c;
        if (index < occupiedCells.length && occupiedCells[index] != null) {
          b.write(occupiedCells[index] ? "X" : "·");
        } else {
          b.write("·");
        }
      }
      b.write("]\n");
      string.write(b.toString());
    }
    return string.toString();
  }

  GridElement getGridElementForRenderBox(RenderBox renderBox) {
    return gridElements[renderBox];
  }
}

class GridPosition {
  int x;
  int y;

  GridPosition(this.x, this.y);
}

/*Either Grid tells its parent how big it is, or parent tells Grid how big it is
If Grid tells parent, then FRs will go to zero
If parent tells grid, then FRs will be whatever, but Grid might not actually fit everything in

process:
1: figure out where each item goes
  * when placed, each item should know which tracks its in, and each track should know what items are in it
2: figure out how big rows and columns are
  * determine fixed size for rows and columns
  * calculate auto columns space
     * for each element in an auto row or column, determine ideal size
     * determine how many auto tracks each element is in for each dimension
     * desiredSpacePerAutocolumn = (desiredSize - fixedTracks - gaps) / numberOfAutoTracks
  * flexSize = fr (value for track) / frSum (sum of values for all tracks) * availableFlexSpace
  * if no flex tracks exist for a given dimension, that space goes to the auto tracks
* (1 and 2 are jobs for GridArray)

*/
class RenderGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GridParentData>,
        DebugOverflowIndicatorMixin {
  List<TrackConstraint> rowConstraints;
  List<TrackConstraint> columnConstraints;
  TrackConstraint rowAutoConstraint;

  GridArray gridArray;
  double gapSize;

  RenderGrid(this.rowConstraints, this.columnConstraints,
      this.rowAutoConstraint, this.gapSize) {
    gridArray = GridArray(
        rowConstraints, columnConstraints, rowAutoConstraint, gapSize);
  }

  @override
  void performLayout() {
    var idealWidth = constraints.maxWidth;
    var idealHeight = constraints.maxHeight;

    gridArray.clear();
//    gridArray.addChildren(firstChild);
    gridArray.solve(getChildrenAsList(), idealWidth, idealHeight);
    size = constraints.constrain(Size(idealWidth, idealHeight));

    RenderBox child = firstChild;
    while (child != null) {
      GridElement element = gridArray.getGridElementForRenderBox(child);
      Track startRow = element.getFirstRow();
      Track endRow = element.getLastRow();
      Track startColumn = element.getFirstColumn();
      Track endColumn = element.getLastColumn();

      double top = gridArray.getTrackStart(startRow);
      double bottom = gridArray.getTrackEnd(endRow);
      double left = gridArray.getTrackStart(startColumn);
      double right = gridArray.getTrackEnd(endColumn);

      double width = right - left;
      double height = bottom - top;

      child.layout(
          BoxConstraints(
              minWidth: width,
              maxWidth: width,
              minHeight: height,
              maxHeight: height),
          parentUsesSize: true);
      print("Placing child at L:$left, T:$top, R:$right, B:$bottom");

      GridParentData data = child.parentData;
      data.offset = Offset(left, top);
      child = nextChild(child);
    }
  }

  RenderBox nextChild(RenderBox box) {
    return (box.parentData as GridParentData).nextSibling;
  }

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! GridParentData) {
      child.parentData = GridParentData();
    }
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    //max sum of rows
    return 200;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    //min sum of rows
    return 200;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    //min sum of columns
    return 200;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    //max sum of columns
    return 200;
  }

  @override
  double computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  @override
  bool hitTestChildren(HitTestResult result, {Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}

/*
* This class exists to allow the child to pass layout information to the parent
*
* In the grid, it will contain:
* 1: information about which cells a child wants to occupy
* 2: information about how a child should fill its cell (if its not big enough to fill it entirely)
*
* */
class GridParentData extends ContainerBoxParentData<RenderBox> {
  Placement hStart = Unspecified();
  Placement hEnd = Span(1);
  Placement vStart = Unspecified();
  Placement vEnd = Span(1);

  bool specifiesPosition() {
    return !(hStart is Unspecified && vStart is Unspecified);
  }
}

class Placement {}

class Unspecified implements Placement {
  const Unspecified();
}

class Line implements Placement {
  final int line;

  const Line(this.line);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Line && runtimeType == other.runtimeType && line == other.line;

  @override
  int get hashCode => line.hashCode;
}

class Span implements Placement {
  final int span;

  const Span(this.span);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Span && runtimeType == other.runtimeType && span == other.span;

  @override
  int get hashCode => span.hashCode;
}

class GridChild extends ParentDataWidget<Grid> {
  Placement hStart;
  Placement hEnd;
  Placement vStart;
  Placement vEnd;

  GridChild(
      {Key key,
      this.hStart = const Unspecified(),
      this.vStart = const Unspecified(),
      this.vEnd = const Span(1),
      this.hEnd = const Span(1),
      @required Widget child})
      : super(key: key, child: child) {
    if (vEnd is Line) {
      assert((vEnd as Line).line > 0);
    }
  }

  /*
  * This method is responsible for ensuring that renderObject.parentData is up to date
  * if it is not, update it, and mark the parent as needing a layout
  * */
  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is GridParentData);
    final GridParentData parentData = renderObject.parentData;
    bool needsLayout = false;
    if (hStart != parentData.hStart) {
      parentData.hStart = hStart;
      needsLayout = true;
    }

    if (vStart != parentData.vStart) {
      parentData.vStart = vStart;
      needsLayout = true;
    }
    if (hEnd != parentData.hEnd) {
      parentData.hEnd = hEnd;
      needsLayout = true;
    }
    if (vEnd != parentData.vEnd) {
      parentData.vEnd = vEnd;
      needsLayout = true;
    }

    if (needsLayout) {
      final AbstractNode targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }
}
