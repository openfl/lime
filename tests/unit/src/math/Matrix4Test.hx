package math;

import lime.math.Matrix3;
import lime.math.Matrix4;
import lime.math.Vector2;
import lime.math.Vector4;
import lime.utils.Float32Array;
import math.MathAssert.*;
import utest.Assert;
import utest.Test;

// Matrix4 mirrors Flash's flash.geom.Matrix3D. Its raw data is column-major,
// so the value in row r and column c is at index c * 4 + r, and the
// translation is at indices 12, 13 and 14. Points are column vectors: append()
// adds a transform that happens after the current one, prepend() one that
// happens before it.
class Matrix4Test extends Test
{
	// Rows of a dense matrix whose determinant is 97
	private static var DENSE:Array<Array<Float>> = [[2, -1, 0, 3], [1, 3, 2, 0], [0, 1, 4, -2], [1, 0, 1, 5]];

	public function new()
	{
		super();
	}

	public function testNewMatrixIsIdentity():Void
	{
		matrix4([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1], new Matrix4());
	}

	public function testNewMatrixUsesTheDataGiven():Void
	{
		var data = [for (i in 0...16) i + 1.0];
		matrix4(data, new Matrix4(new Float32Array(data)));
	}

	public function testIdentityResetsTheMatrix():Void
	{
		var m = fromRows(DENSE);
		m.identity();
		matrix4([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1], m);
	}

	public function testCloneIsIndependent():Void
	{
		var m = fromRows(DENSE);
		var copy = m.clone();
		sameMatrix4(m, copy);

		copy[0] = 100;
		near(2, m[0], "original after changing the clone");
	}

	public function testCopyFromCopiesEachValue():Void
	{
		var source = fromRows(DENSE);
		var m = new Matrix4();
		m.copyFrom(source);
		sameMatrix4(source, m);

		source[0] = 100;
		near(2, m[0], "copy after changing the source");
	}

	public function testAppendTranslationSetsTheLastColumn():Void
	{
		var m = new Matrix4();
		m.appendTranslation(1, 2, 3);
		matrix4([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 2, 3, 1], m);
	}

	public function testPositionGetsAndSetsTheTranslation():Void
	{
		var m = fromRows([[2, 0, 0, 1], [0, 3, 0, 2], [0, 0, 4, 3], [0, 0, 0, 1]]);
		vector3(1, 2, 3, m.position);

		m.position = new Vector4(7, 8, 9);
		matrix4([2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 4, 0, 7, 8, 9, 1], m);
	}

	public function testTransformVectorAppliesTranslationWhateverW():Void
	{
		// Flash's transformVector treats every input as a point: a Vector4
		// with the default w of 0 is still translated
		var m = fromRows([[2, 0, 0, 10], [0, 3, 0, 20], [0, 0, 4, 30], [0, 0, 0, 1]]);
		vector3(12, 26, 34, m.transformVector(new Vector4(1, 2, 1)));
		vector3(12, 26, 34, m.transformVector(new Vector4(1, 2, 1, 1)), "with w of 1");
	}

	public function testTransformVectorAppliesTheWholeMatrix():Void
	{
		// Rows of DENSE dotted with (1, 2, 3, 1); only x, y and z are compared
		var m = fromRows(DENSE);
		vector3(2 - 2 + 0 + 3, 1 + 6 + 6 + 0, 0 + 2 + 12 - 2, m.transformVector(new Vector4(1, 2, 3)));
	}

	public function testDeltaTransformVectorIgnoresTranslation():Void
	{
		var m = fromRows([[2, 0, 0, 10], [0, 3, 0, 20], [0, 0, 4, 30], [0, 0, 0, 1]]);
		vector3(2, 6, 4, m.deltaTransformVector(new Vector4(1, 2, 1)));
	}

	@Ignored("Waiting on #2140")
	public function testDeltaTransformVectorUsesOnlyTheUpperLeft3x3():Void
	{
		// Rows of DENSE without the translation column, dotted with (1, 2, 3).
		// The bottom row (1, 0, 1, 5) only affects w, never x, y or z.
		var m = fromRows(DENSE);
		vector3(2 - 2 + 0, 1 + 6 + 6, 0 + 2 + 12, m.deltaTransformVector(new Vector4(1, 2, 3)));
	}

	public function testTransformVectorFillsTheResultGiven():Void
	{
		var m = translation(1, 2, 3);
		var result = new Vector4();
		var returned = m.transformVector(new Vector4(1, 1, 1), result);
		Assert.isTrue(returned == result, "returns the result given");
		vector3(2, 3, 4, result);

		var delta = new Vector4();
		var returnedDelta = m.deltaTransformVector(new Vector4(1, 1, 1), delta);
		Assert.isTrue(returnedDelta == delta, "returns the result given");
		vector3(1, 1, 1, delta);
	}

	public function testTransformVectorsTransformsEachTriple():Void
	{
		var m = fromRows([[2, 0, 0, 10], [0, 3, 0, 20], [0, 0, 4, 30], [0, 0, 0, 1]]);
		var input = new Float32Array([1.0, 1, 1, -1, 0, 2]);
		var output = new Float32Array(6);
		m.transformVectors(input, output);

		var expected = [12.0, 23, 34, 8, 20, 38];
		for (i in 0...6)
		{
			near(expected[i], output[i], "value " + i);
		}
	}

	public function testAppendAppliesAfterTheExistingTransform():Void
	{
		// Flash: m.append(lhs) gives lhs * m
		var m = scaling(2, 2, 2);
		m.append(translation(1, 0, 0));
		vector3(3, 0, 0, m.transformVector(new Vector4(1, 0, 0)));
	}

	public function testPrependAppliesBeforeTheExistingTransform():Void
	{
		// Flash: m.prepend(rhs) gives m * rhs
		var m = scaling(2, 2, 2);
		m.prepend(translation(1, 0, 0));
		vector3(4, 0, 0, m.transformVector(new Vector4(1, 0, 0)));
	}

	public function testAppendAndPrependMatchMatrixMultiplication():Void
	{
		var other = fromRows([[1, 2, 0, 5], [0, 1, 3, 6], [4, 0, 1, 7], [0, 0, 0, 1]]);

		var appended = fromRows(DENSE);
		appended.append(other);
		matrix4(multiply(other, fromRows(DENSE)), appended, "append gives other * m");

		var prepended = fromRows(DENSE);
		prepended.prepend(other);
		matrix4(multiply(fromRows(DENSE), other), prepended, "prepend gives m * other");
	}

	public function testAppendScaleScalesTheTranslation():Void
	{
		var m = translation(1, 2, 3);
		m.appendScale(2, 3, 4);
		matrix4([2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 4, 0, 2, 6, 12, 1], m);
	}

	public function testPrependScaleLeavesTheTranslation():Void
	{
		var m = translation(1, 2, 3);
		m.prependScale(2, 3, 4);
		matrix4([2, 0, 0, 0, 0, 3, 0, 0, 0, 0, 4, 0, 1, 2, 3, 1], m);
	}

	public function testAppendTranslationAddsToThePosition():Void
	{
		// Documented as increasing the position, whatever the matrix scales by
		var m = scaling(2, 2, 2);
		m.appendTranslation(1, 2, 3);
		vector3(1, 2, 3, m.position);

		m.appendTranslation(1, 1, 1);
		vector3(2, 3, 4, m.position);
	}

	public function testPrependTranslationIsTransformedByTheMatrix():Void
	{
		var m = scaling(2, 2, 2);
		m.prependTranslation(1, 2, 3);
		vector3(2, 4, 6, m.position);
		vector3(4, 4, 6, m.transformVector(new Vector4(1, 0, 0)));
	}

	public function testAppendRotationAboutZFollowsTheRightHandRule():Void
	{
		// A positive quarter turn about +z takes +x to +y, and +y to -x
		var m = new Matrix4();
		m.appendRotation(90, new Vector4(0, 0, 1));
		vector3(0, 1, 0, m.transformVector(new Vector4(1, 0, 0)), "x axis");
		vector3(-1, 0, 0, m.transformVector(new Vector4(0, 1, 0)), "y axis");
		vector3(0, 0, 1, m.transformVector(new Vector4(0, 0, 1)), "z axis");
		near(1, m.determinant, "a rotation keeps volume");
	}

	public function testAppendRotationAboutXAndYFollowsTheRightHandRule():Void
	{
		var aboutX = new Matrix4();
		aboutX.appendRotation(90, new Vector4(1, 0, 0));
		vector3(0, 0, 1, aboutX.transformVector(new Vector4(0, 1, 0)), "about x, +y goes to +z");

		var aboutY = new Matrix4();
		aboutY.appendRotation(90, new Vector4(0, 1, 0));
		vector3(1, 0, 0, aboutY.transformVector(new Vector4(0, 0, 1)), "about y, +z goes to +x");
	}

	public function testAppendRotationAboutADiagonalAxis():Void
	{
		// A third of a turn about (1, 1, 1) cycles the axes x -> y -> z -> x
		var axis = new Vector4(1, 1, 1);
		axis.normalize();

		var m = new Matrix4();
		m.appendRotation(120, axis);
		vector3(0, 1, 0, m.transformVector(new Vector4(1, 0, 0)), "x axis");
		vector3(0, 0, 1, m.transformVector(new Vector4(0, 1, 0)), "y axis");
		vector3(1, 0, 0, m.transformVector(new Vector4(0, 0, 1)), "z axis");
	}

	public function testAppendRotationAppliesAfterTheExistingTransform():Void
	{
		var m = translation(10, 0, 0);
		m.appendRotation(90, new Vector4(0, 0, 1));
		vector3(0, 11, 0, m.transformVector(new Vector4(1, 0, 0)));
		vector3(0, 10, 0, m.position, "the translation is rotated too");
	}

	public function testPrependRotationAppliesBeforeTheExistingTransform():Void
	{
		var m = translation(10, 0, 0);
		m.prependRotation(90, new Vector4(0, 0, 1));
		vector3(10, 1, 0, m.transformVector(new Vector4(1, 0, 0)));
		vector3(10, 0, 0, m.position, "the translation is unchanged");
	}

	@Ignored("Waiting on #2139")
	public function testAppendRotationTurnsAboutThePivotPoint():Void
	{
		var m = new Matrix4();
		m.appendRotation(90, new Vector4(0, 0, 1), new Vector4(1, 1, 0));
		vector3(1, 1, 0, m.transformVector(new Vector4(1, 1, 0)), "the pivot stays put");
		vector3(1, 2, 0, m.transformVector(new Vector4(2, 1, 0)), "one to the right of the pivot");
		vector3(2, 0, 0, m.transformVector(new Vector4(0, 0, 0)), "the origin");
	}

	@Ignored("Waiting on #2139")
	public function testAppendRotationAboutAPivotAppliesAfterTheExistingTransform():Void
	{
		var m = translation(1, 0, 0);
		m.appendRotation(90, new Vector4(0, 0, 1), new Vector4(1, 1, 0));
		// (1, 0, 0) moves to (2, 0, 0), then turns about (1, 1) to (2, 2)
		vector3(2, 2, 0, m.transformVector(new Vector4(1, 0, 0)));
	}

	@Ignored("Waiting on #2139")
	public function testPrependRotationTurnsAboutThePivotPointFirst():Void
	{
		var m = translation(10, 0, 0);
		m.prependRotation(90, new Vector4(0, 0, 1), new Vector4(1, 1, 0));
		vector3(11, 2, 0, m.transformVector(new Vector4(2, 1, 0)));
		vector3(11, 1, 0, m.transformVector(new Vector4(1, 1, 0)), "the pivot only moves by the translation");
	}

	public function testDeterminant():Void
	{
		near(1, new Matrix4().determinant, "identity");
		near(1, translation(5, 6, 7).determinant, "translation");
		near(24, scaling(2, 3, 4).determinant, "scale");
		near(-1, scaling(-1, 1, 1).determinant, "mirror");
		near(0, scaling(1, 0, 1).determinant, "flattened");
		near(97, fromRows(DENSE).determinant, "dense");
		near(3, fromRows([[4, 0, 0, 1], [0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 1]]).determinant, "projective bottom row");
	}

	public function testInvertGivesTheInverse():Void
	{
		var m = fromRows(DENSE);
		var inverse = m.clone();
		Assert.isTrue(inverse.invert(), "invert succeeds");

		var product = m.clone();
		product.append(inverse);
		matrix4([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1], product, "inverse * m");

		product = m.clone();
		product.prepend(inverse);
		matrix4([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1], product, "m * inverse");
	}

	public function testInvertOfATransform():Void
	{
		var m = fromRows([[2, 0, 0, 10], [0, 4, 0, 20], [0, 0, 5, 30], [0, 0, 0, 1]]);
		Assert.isTrue(m.invert());
		matrix4([0.5, 0, 0, 0, 0, 0.25, 0, 0, 0, 0, 0.2, 0, -5, -5, -6, 1], m);
	}

	public function testInvertOfAMirrorSucceeds():Void
	{
		// The determinant is -1; a matrix is invertible whenever it is not 0
		var m = scaling(-1, 1, 1);
		Assert.isTrue(m.invert(), "invert of a mirror");
		matrix4([-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1], m);
	}

	public function testInvertOfASingularMatrixFails():Void
	{
		var m = scaling(1, 0, 1);
		Assert.isFalse(m.invert(), "invert of a flattened matrix");

		for (i in 0...16)
		{
			Assert.isFalse(Math.isNaN(m[i]) || !Math.isFinite(m[i]), "after a failed invert: " + describeMatrix4(m));
		}
	}

	public function testTransposeSwapsRowsAndColumns():Void
	{
		var m = fromRows(DENSE);
		m.transpose();
		sameMatrix4(fromRows([for (c in 0...4) [for (r in 0...4) DENSE[r][c]]]), m);
	}

	public function testCopyColumnToAndFrom():Void
	{
		// Column 1 of DENSE
		var m = fromRows(DENSE);
		var v = new Vector4();
		m.copyColumnTo(1, v);
		vector4(-1, 3, 1, 0, v);

		var target = new Matrix4();
		target.copyColumnFrom(2, new Vector4(5, 6, 7, 8));
		matrix4([1, 0, 0, 0, 0, 1, 0, 0, 5, 6, 7, 8, 0, 0, 0, 1], target);
	}

	public function testCopyRowToAndFrom():Void
	{
		// Row 1 of DENSE
		var m = fromRows(DENSE);
		var v = new Vector4();
		m.copyRowTo(1, v);
		vector4(1, 3, 2, 0, v);

		var target = new Matrix4();
		target.copyRowFrom(2, new Vector4(5, 6, 7, 8));
		matrix4([1, 0, 5, 0, 0, 1, 6, 0, 0, 0, 7, 0, 0, 0, 8, 1], target);
	}

	public function testCreate2DMatchesTheMatrix3Transform():Void
	{
		var m3 = new Matrix3(2, 3, 4, 5, 6, 7);
		var m = fromRows(DENSE);
		m.create2D(2, 3, 4, 5, 6, 7);

		matrix4([2, 3, 0, 0, 4, 5, 0, 0, 0, 0, 1, 0, 6, 7, 0, 1], m);
		var expected = m3.transformVector(new Vector2(1, 10));
		vector3(expected.x, expected.y, 5, m.transformVector(new Vector4(1, 10, 5)));
	}

	public function testConvertsFromMatrix3():Void
	{
		var m:Matrix4 = new Matrix3(2, 3, 4, 5, 6, 7);
		matrix4([2, 3, 0, 0, 4, 5, 0, 0, 0, 0, 1, 0, 6, 7, 0, 1], m);
	}

	public function testInterpolateReachesEachEnd():Void
	{
		var from = translation(1, 2, 3);
		// Scale by 2, a quarter turn about z, then move to (11, 22, 33)
		var to = fromRows([[0, -2, 0, 11], [2, 0, 0, 22], [0, 0, 2, 33], [0, 0, 0, 1]]);

		sameMatrix4(from, Matrix4.interpolate(from, to, 0), "at 0");
		sameMatrix4(to, Matrix4.interpolate(from, to, 1), "at 1");
	}

	public function testInterpolateMovesTheTranslationLinearly():Void
	{
		var m = Matrix4.interpolate(new Matrix4(), translation(10, 20, 30), 0.25);
		matrix4([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 2.5, 5, 7.5, 1], m);
	}

	@Ignored("Waiting on #2140")
	public function testInterpolateTurnsTheRotation():Void
	{
		// Flash interpolates the rotation as a quaternion, so halfway to a
		// quarter turn is an eighth of a turn, still a pure rotation
		var to = new Matrix4();
		to.appendRotation(90, new Vector4(0, 0, 1));

		var m = Matrix4.interpolate(new Matrix4(), to, 0.5);
		var half = Math.sqrt(0.5);
		vector3(half, half, 0, m.transformVector(new Vector4(1, 0, 0)));
		near(1, m.determinant, "a rotation keeps volume");
	}

	public function testInterpolateFillsTheResultGiven():Void
	{
		var result = fromRows(DENSE);
		var returned = Matrix4.interpolate(new Matrix4(), translation(10, 20, 30), 0.5, result);
		matrix4([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 5, 10, 15, 1], result);
		matrix4([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 5, 10, 15, 1], returned);
	}

	public function testInterpolateToChangesTheCurrentMatrix():Void
	{
		var m = new Matrix4();
		m.interpolateTo(translation(10, 20, 30), 0.5);
		matrix4([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 5, 10, 15, 1], m);

		m.interpolateTo(translation(10, 20, 30), 1);
		matrix4([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 10, 20, 30, 1], m);
	}

	@Ignored("Waiting on #2140")
	public function testPointAtTurnsTheForwardVectorToTheTarget():Void
	{
		var m = new Matrix4();
		m.pointAt(new Vector4(10, 0, 0), new Vector4(0, 0, -1), new Vector4(0, -1, 0));

		var forward = m.deltaTransformVector(new Vector4(0, 0, -1));
		forward.normalize();
		vector3(1, 0, 0, forward, "the at vector points at the target");
		vector3(0, 0, 0, m.position, "the position is kept");
		near(1, m.determinant, "a rotation, not a mirror or a scale");
	}

	@Ignored("Waiting on #2140")
	public function testPointAtAimsFromThePosition():Void
	{
		// The target is in absolute coordinates, so the direction is from the
		// matrix's own position
		var m = translation(5, 0, 0);
		m.pointAt(new Vector4(5, 0, 10), new Vector4(0, 0, -1), new Vector4(0, -1, 0));

		var forward = m.deltaTransformVector(new Vector4(0, 0, -1));
		forward.normalize();
		vector3(0, 0, 1, forward, "the at vector points at the target");
		vector3(5, 0, 0, m.position, "the position is kept");
	}

	@Ignored("Waiting on #2140")
	public function testPointAtWithAnotherForwardVector():Void
	{
		var m = new Matrix4();
		m.pointAt(new Vector4(0, 10, 0), new Vector4(1, 0, 0), new Vector4(0, 0, 1));

		var forward = m.deltaTransformVector(new Vector4(1, 0, 0));
		forward.normalize();
		vector3(0, 1, 0, forward, "the at vector points at the target");
		near(1, m.determinant, "a rotation, not a mirror or a scale");
	}

	public function testCreateOrthoMatchesGlOrtho():Void
	{
		// glOrtho(l, r, b, t, n, f):
		// [ 2/(r-l)  0        0         -(r+l)/(r-l) ]
		// [ 0        2/(t-b)  0         -(t+b)/(t-b) ]
		// [ 0        0        -2/(f-n)  -(f+n)/(f-n) ]
		// [ 0        0        0          1           ]
		var m = new Matrix4();
		m.createOrtho(-2, 6, -1, 3, 0.5, 10);
		matrix4([0.25, 0, 0, 0, 0, 0.5, 0, 0, 0, 0, -2 / 9.5, 0, -0.5, -0.5, -10.5 / 9.5, 1], m);
	}

	public function testCreateOrthoMapsTheViewVolumeToTheClipCube():Void
	{
		// The eye looks down -z, so the near plane is at z = -near
		var m = new Matrix4();
		m.createOrtho(-2, 6, -1, 3, 0.5, 10);
		vector4(-1, -1, -1, 1, clip(m, -2, -1, -0.5), "left, bottom, near");
		vector4(1, 1, 1, 1, clip(m, 6, 3, -10), "right, top, far");
	}

	@Ignored("Waiting on #2138")
	public function testCreatePerspectiveMatchesGluPerspective():Void
	{
		// gluPerspective(fovy, aspect, n, f), with f' = cot(fovy / 2):
		// [ f'/aspect  0   0             0           ]
		// [ 0          f'  0             0           ]
		// [ 0          0   (f+n)/(n-f)   2fn/(n-f)   ]
		// [ 0          0   -1            0           ]
		var m = new Matrix4();
		m.createPerspective(60, 1.5, 0.5, 50);

		var cot = 1 / Math.tan(30 * Math.PI / 180);
		matrix4([cot / 1.5, 0, 0, 0, 0, cot, 0, 0, 0, 0, 50.5 / -49.5, -1, 0, 0, 50 / -49.5, 0], m);
	}

	public function testCreatePerspectiveTakesWFromTheDepth():Void
	{
		// The bottom row is (0, 0, -1, 0), so w is the distance in front of the eye
		var m = new Matrix4();
		m.createPerspective(60, 1.5, 0.5, 50);
		near(0, m[3], "row 3, column 0");
		near(0, m[7], "row 3, column 1");
		near(-1, m[11], "row 3, column 2");
		near(0, m[15], "row 3, column 3");
	}

	public function testCreatePerspectiveMapsTheNearAndFarPlanesToTheClipRange():Void
	{
		var m = new Matrix4();
		m.createPerspective(60, 1.5, 0.5, 50);

		var nearPoint = clip(m, 0, 0, -0.5);
		near(-1, nearPoint.z / nearPoint.w, "depth on the near plane, clip " + describeVector4(nearPoint));
		var farPoint = clip(m, 0, 0, -50);
		near(1, farPoint.z / farPoint.w, "depth on the far plane, clip " + describeVector4(farPoint));
	}

	public function testCreatePerspectiveScalesXByTheAspectRatio():Void
	{
		var m = new Matrix4();
		m.createPerspective(60, 1.5, 0.5, 50);
		near(1.5, m[5] / m[0]);
	}

	@Ignored("Waiting on #2138")
	public function testCreatePerspectiveFieldOfViewIsVerticalInDegrees():Void
	{
		// As in gluPerspective, the top and right edges of a 60 degree view
		// land on the edges of clip space
		var m = new Matrix4();
		m.createPerspective(60, 1.5, 0.5, 50);

		var halfHeight = 0.5 * Math.tan(30 * Math.PI / 180);
		var top = clip(m, 0, halfHeight, -0.5);
		near(1, top.y / top.w, "top edge, clip " + describeVector4(top));
		var right = clip(m, halfHeight * 1.5, 0, -0.5);
		near(1, right.x / right.w, "right edge, clip " + describeVector4(right));
	}

	private static function fromRows(rows:Array<Array<Float>>):Matrix4
	{
		var data = new Float32Array(16);
		for (r in 0...4)
		{
			for (c in 0...4)
			{
				data[c * 4 + r] = rows[r][c];
			}
		}
		return new Matrix4(data);
	}

	private static function translation(x:Float, y:Float, z:Float):Matrix4
	{
		return fromRows([[1, 0, 0, x], [0, 1, 0, y], [0, 0, 1, z], [0, 0, 0, 1]]);
	}

	private static function scaling(x:Float, y:Float, z:Float):Matrix4
	{
		return fromRows([[x, 0, 0, 0], [0, y, 0, 0], [0, 0, z, 0], [0, 0, 0, 1]]);
	}

	/**
		The textbook product lhs * rhs, as column-major values.
	**/
	private static function multiply(lhs:Matrix4, rhs:Matrix4):Array<Float>
	{
		var result = [];
		for (c in 0...4)
		{
			for (r in 0...4)
			{
				var sum = 0.0;
				for (k in 0...4)
				{
					sum += lhs[k * 4 + r] * rhs[c * 4 + k];
				}
				result[c * 4 + r] = sum;
			}
		}
		return result;
	}

	/**
		The matrix times the point (x, y, z, 1), read from the raw values.
	**/
	private static function clip(m:Matrix4, x:Float, y:Float, z:Float):Vector4
	{
		return new Vector4(m[0] * x + m[4] * y + m[8] * z + m[12], m[1] * x + m[5] * y + m[9] * z + m[13], m[2] * x + m[6] * y + m[10] * z + m[14],
			m[3] * x + m[7] * y + m[11] * z + m[15]);
	}
}
