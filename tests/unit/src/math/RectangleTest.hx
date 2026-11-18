package math;

import lime.math.Matrix3;
import lime.math.Rectangle;
import lime.math.Vector2;
import math.MathAssert.*;
import utest.Assert;
import utest.Test;

// Rectangle mirrors Flash's flash.geom.Rectangle: the left and top edges are
// inside the rectangle, the right and bottom edges are not.
class RectangleTest extends Test
{
	public function new()
	{
		super();
	}

	public function testNewRectangleIsEmptyAtTheOrigin():Void
	{
		var r = new Rectangle();
		rectangle(0, 0, 0, 0, r);
		Assert.isTrue(r.isEmpty());
	}

	public function testEdges():Void
	{
		var r = new Rectangle(10, 20, 30, 40);
		near(10, r.left, "left");
		near(20, r.top, "top");
		near(40, r.right, "right");
		near(60, r.bottom, "bottom");
		vector2(10, 20, r.topLeft, "topLeft");
		vector2(40, 60, r.bottomRight, "bottomRight");
		vector2(30, 40, r.size, "size");
	}

	public function testContainsIncludesTheTopLeftEdges():Void
	{
		var r = new Rectangle(0, 0, 10, 10);
		Assert.isTrue(r.contains(0, 0), "top-left corner");
		Assert.isTrue(r.contains(0, 5), "left edge");
		Assert.isTrue(r.contains(5, 0), "top edge");
		Assert.isTrue(r.contains(9.999, 9.999), "just inside the bottom-right corner");
	}

	public function testContainsExcludesTheBottomRightEdges():Void
	{
		var r = new Rectangle(0, 0, 10, 10);
		Assert.isFalse(r.contains(10, 5), "right edge");
		Assert.isFalse(r.contains(5, 10), "bottom edge");
		Assert.isFalse(r.contains(10, 10), "bottom-right corner");
		Assert.isFalse(r.contains(-0.001, 5), "just left of the rectangle");
		Assert.isFalse(r.contains(5, -0.001), "just above the rectangle");
	}

	public function testContainsVectorIncludesTheTopLeftOnly():Void
	{
		var r = new Rectangle(0, 0, 10, 10);
		Assert.isTrue(r.containsVector(new Vector2(0, 0)), "containsVector at the top-left");
		Assert.isFalse(r.containsVector(new Vector2(10, 10)), "containsVector at the bottom-right");
	}

	public function testContainsRectIncludesSharedEdges():Void
	{
		// The right and bottom of a contained rectangle are outside it too,
		// so a rectangle can reach this one's right and bottom edges
		var r = new Rectangle(0, 0, 10, 10);
		Assert.isTrue(r.containsRect(new Rectangle(0, 0, 10, 10)), "the same rectangle");
		Assert.isTrue(r.containsRect(new Rectangle(5, 5, 5, 5)), "sharing the bottom-right corner");
		Assert.isTrue(r.containsRect(new Rectangle(2, 2, 3, 3)), "well inside");
	}

	public function testContainsRectRejectsOverlaps():Void
	{
		var r = new Rectangle(0, 0, 10, 10);
		Assert.isFalse(r.containsRect(new Rectangle(5, 5, 6, 5)), "past the right edge");
		Assert.isFalse(r.containsRect(new Rectangle(5, 5, 5, 6)), "past the bottom edge");
		Assert.isFalse(r.containsRect(new Rectangle(-1, 0, 5, 5)), "past the left edge");
		Assert.isFalse(r.containsRect(new Rectangle(0, -1, 5, 5)), "past the top edge");
		Assert.isFalse(r.containsRect(new Rectangle(20, 20, 5, 5)), "outside");
	}

	public function testIntersectsNeedsAnOverlappingArea():Void
	{
		var r = new Rectangle(0, 0, 10, 10);
		Assert.isTrue(r.intersects(new Rectangle(5, 5, 10, 10)), "overlapping");
		Assert.isTrue(r.intersects(new Rectangle(2, 2, 3, 3)), "inside");
		Assert.isTrue(r.intersects(new Rectangle(-5, -5, 20, 20)), "around");
		Assert.isFalse(r.intersects(new Rectangle(10, 0, 10, 10)), "touching on the right");
		Assert.isFalse(r.intersects(new Rectangle(0, 10, 10, 10)), "touching below");
		Assert.isFalse(r.intersects(new Rectangle(-10, 0, 10, 10)), "touching on the left");
		Assert.isFalse(r.intersects(new Rectangle(20, 20, 5, 5)), "apart");
		Assert.isTrue(new Rectangle(5, 5, 10, 10).intersects(r), "overlapping, the other way round");
	}

	public function testIntersectionOfOverlappingRectangles():Void
	{
		var r = new Rectangle(0, 0, 10, 10);
		rectangle(5, 5, 5, 5, r.intersection(new Rectangle(5, 5, 10, 10)), "overlapping");
		rectangle(2, 3, 4, 5, r.intersection(new Rectangle(2, 3, 4, 5)), "inside");
		rectangle(0, 0, 10, 10, r.intersection(new Rectangle(-5, -5, 20, 20)), "around");
		rectangle(-2, -3, 4, 5, new Rectangle(-5, -5, 7, 7).intersection(new Rectangle(-2, -3, 10, 10)), "at negative coordinates");
	}

	public function testIntersectionOfTouchingOrSeparateRectanglesIsEmpty():Void
	{
		// Flash: "If the rectangles do not intersect, this method returns an
		// empty Rectangle object with its properties set to 0"
		var r = new Rectangle(0, 0, 10, 10);
		var touching = r.intersection(new Rectangle(10, 0, 10, 10));
		Assert.isTrue(touching.isEmpty(), "touching gave " + describeRectangle(touching));
		rectangle(0, 0, 0, 0, touching, "touching");

		var apart = r.intersection(new Rectangle(20, 30, 5, 5));
		Assert.isTrue(apart.isEmpty(), "apart gave " + describeRectangle(apart));
		rectangle(0, 0, 0, 0, apart, "apart");
	}

	public function testIntersectionFillsTheResultGiven():Void
	{
		var result = new Rectangle(1, 1, 1, 1);
		var returned = new Rectangle(0, 0, 10, 10).intersection(new Rectangle(5, 5, 10, 10), result);
		Assert.isTrue(returned == result, "returns the result given");
		rectangle(5, 5, 5, 5, result);
	}

	public function testUnionCoversBothRectangles():Void
	{
		var r = new Rectangle(0, 0, 10, 10);
		rectangle(0, 0, 25, 35, r.union(new Rectangle(20, 30, 5, 5)), "apart");
		rectangle(-5, -5, 15, 15, r.union(new Rectangle(-5, -5, 10, 10)), "overlapping");
		rectangle(0, 0, 10, 10, r.union(new Rectangle(2, 2, 3, 3)), "inside");
		rectangle(0, 0, 10, 10, r, "the rectangle itself is unchanged");
	}

	public function testUnionIgnoresEmptyRectangles():Void
	{
		// Flash: "The union() method ignores rectangles with 0 as the height or width value"
		var r = new Rectangle(10, 10, 10, 10);
		rectangle(10, 10, 10, 10, r.union(new Rectangle(100, 100, 0, 0)), "with an empty rectangle");
		rectangle(10, 10, 10, 10, r.union(new Rectangle(0, 0, 0, 50)), "with a zero width rectangle");
		rectangle(10, 10, 10, 10, new Rectangle(0, 0, 0, 0).union(r), "an empty rectangle with this one");
	}

	public function testUnionFillsTheResultGiven():Void
	{
		var result = new Rectangle();
		var returned = new Rectangle(0, 0, 10, 10).union(new Rectangle(20, 30, 5, 5), result);
		Assert.isTrue(returned == result, "returns the result given");
		rectangle(0, 0, 25, 35, result);
	}

	public function testIsEmptyForZeroOrNegativeSizes():Void
	{
		// Documented as true when the width or height is <= 0
		Assert.isTrue(new Rectangle(0, 0, 0, 10).isEmpty(), "zero width");
		Assert.isTrue(new Rectangle(0, 0, 10, 0).isEmpty(), "zero height");
		Assert.isTrue(new Rectangle(0, 0, -1, 10).isEmpty(), "negative width");
		Assert.isTrue(new Rectangle(0, 0, 10, -1).isEmpty(), "negative height");
		Assert.isFalse(new Rectangle(-5, -5, 1, 1).isEmpty(), "a small rectangle");
	}

	public function testSetEmptyClearsEveryValue():Void
	{
		var r = new Rectangle(1, 2, 3, 4);
		r.setEmpty();
		rectangle(0, 0, 0, 0, r);
	}

	public function testInflateGrowsAroundTheCentre():Void
	{
		// Flash: the size grows by dx on the left and on the right, and by dy
		// on the top and on the bottom
		var r = new Rectangle(10, 10, 20, 20);
		r.inflate(5, 3);
		rectangle(5, 7, 30, 26, r);
	}

	public function testInflateVectorGrowsAroundTheCentre():Void
	{
		var r = new Rectangle(10, 10, 20, 20);
		r.inflateVector(new Vector2(5, 3));
		rectangle(5, 7, 30, 26, r);
	}

	public function testOffsetMovesWithoutResizing():Void
	{
		var r = new Rectangle(1, 2, 3, 4);
		r.offset(10, -20);
		rectangle(11, -18, 3, 4, r, "offset");
		r.offsetVector(new Vector2(-1, 1));
		rectangle(10, -17, 3, 4, r, "offsetVector");
	}

	public function testSettingLeftOrTopKeepsTheOppositeEdge():Void
	{
		// Flash: changing left or top changes the width or height, unlike x or y
		var r = new Rectangle(10, 20, 30, 40);
		r.left = 15;
		rectangle(15, 20, 25, 40, r, "left");
		r.top = 30;
		rectangle(15, 30, 25, 30, r, "top");
		near(40, r.right, "right after setting left");
		near(60, r.bottom, "bottom after setting top");
	}

	public function testSettingRightOrBottomResizes():Void
	{
		var r = new Rectangle(10, 20, 30, 40);
		r.right = 100;
		rectangle(10, 20, 90, 40, r, "right");
		r.bottom = 25;
		rectangle(10, 20, 90, 5, r, "bottom");
	}

	public function testSettingTopLeftBottomRightAndSize():Void
	{
		var r = new Rectangle(10, 20, 30, 40);
		r.size = new Vector2(5, 6);
		rectangle(10, 20, 5, 6, r, "size");

		r.bottomRight = new Vector2(100, 200);
		rectangle(10, 20, 90, 180, r, "bottomRight");

		r.topLeft = new Vector2(1, 2);
		near(1, r.x, "x after setting topLeft");
		near(2, r.y, "y after setting topLeft");
	}

	public function testEqualsComparesEveryValue():Void
	{
		var r = new Rectangle(1, 2, 3, 4);
		Assert.isTrue(r.equals(new Rectangle(1, 2, 3, 4)));
		Assert.isFalse(r.equals(new Rectangle(0, 2, 3, 4)), "x differs");
		Assert.isFalse(r.equals(new Rectangle(1, 0, 3, 4)), "y differs");
		Assert.isFalse(r.equals(new Rectangle(1, 2, 0, 4)), "width differs");
		Assert.isFalse(r.equals(new Rectangle(1, 2, 3, 0)), "height differs");
		Assert.isFalse(r.equals(null), "null");
	}

	public function testCloneAndCopyFromAreIndependent():Void
	{
		var r = new Rectangle(1, 2, 3, 4);
		var copy = r.clone();
		rectangle(1, 2, 3, 4, copy, "clone");
		copy.x = 10;
		near(1, r.x, "original after changing the clone");

		var target = new Rectangle();
		target.copyFrom(r);
		rectangle(1, 2, 3, 4, target, "copyFrom");
		r.width = 50;
		near(3, target.width, "copy after changing the source");
	}

	public function testSetTo():Void
	{
		var r = new Rectangle();
		r.setTo(1, 2, 3, 4);
		rectangle(1, 2, 3, 4, r);
	}

	@Ignored("Waiting on #2137")
	public function testTransformByAMatrixGivesTheBounds():Void
	{
		// A quarter turn and a move: (x, y) becomes (10 - y, 20 + x). The
		// corners of (1, 2, 3, 4) land on x 4 to 8 and y 21 to 24.
		var m = new Matrix3(0, 1, -1, 0, 10, 20);
		rectangle(4, 21, 4, 3, m.transformRect(new Rectangle(1, 2, 3, 4)));
	}

	@Ignored("Waiting on #2137")
	public function testTransformByAMirrorGivesPositiveSize():Void
	{
		var m = new Matrix3(-2, 0, 0, 1, 0, 0);
		rectangle(-8, 2, 6, 4, m.transformRect(new Rectangle(1, 2, 3, 4)));
	}

	@Ignored("Waiting on #2137")
	public function testTransformBySkewGivesTheBounds():Void
	{
		// (x, y) becomes (x + y, y): the corners of (0, 0, 10, 10) land on
		// x 0 to 20
		var m = new Matrix3(1, 0, 1, 1, 0, 0);
		rectangle(0, 0, 20, 10, m.transformRect(new Rectangle(0, 0, 10, 10)));
	}

	@Ignored("Waiting on #2137")
	public function testTransformFillsTheResultGiven():Void
	{
		var m = new Matrix3(2, 0, 0, 2, 1, 1);
		var source = new Rectangle(1, 2, 3, 4);
		var result = new Rectangle();
		var returned = m.transformRect(source, result);
		Assert.isTrue(returned == result, "returns the result given");
		rectangle(3, 5, 6, 8, result);
		rectangle(1, 2, 3, 4, source, "the source is unchanged");
	}
}
