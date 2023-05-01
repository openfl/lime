package lime.math;

import lime.utils.Float32Array;
import lime.utils.Log;

/**
	`Matrix4` is a 4x4 matrix, useful for 3D calculations
**/
abstract Matrix4(Float32Array) from Float32Array to Float32Array
{
	private static var __identity:Array<Float> = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0];

	/**
		Gets the determinant of the matrix
	**/
	public var determinant(get, never):Float;

	/**
		Gets or sets the position value of this matrix
	**/
	public var position(get, set):Vector4;

	/**
		Creates a new matrix instance
		@param	data	(Optional) A `Float32Array` of 16 values to use for this matrix
	**/
	public function new(data:Float32Array = null)
	{
		if (data != null && data.length == 16)
		{
			this = data;
		}
		else
		{
			this = new Float32Array(__identity);
		}
	}

	/**
		Appends a second matrix by multiplying its values against the current one
		@param	lhs	A second matrix instance
	**/
	public function append(lhs:Matrix4):Void
	{
		var m111:Float = this[0],
			m121:Float = this[4],
			m131:Float = this[8],
			m141:Float = this[12],
			m112:Float = this[1],
			m122:Float = this[5],
			m132:Float = this[9],
			m142:Float = this[13],
			m113:Float = this[2],
			m123:Float = this[6],
			m133:Float = this[10],
			m143:Float = this[14],
			m114:Float = this[3],
			m124:Float = this[7],
			m134:Float = this[11],
			m144:Float = this[15],
			m211:Float = lhs[0],
			m221:Float = lhs[4],
			m231:Float = lhs[8],
			m241:Float = lhs[12],
			m212:Float = lhs[1],
			m222:Float = lhs[5],
			m232:Float = lhs[9],
			m242:Float = lhs[13],
			m213:Float = lhs[2],
			m223:Float = lhs[6],
			m233:Float = lhs[10],
			m243:Float = lhs[14],
			m214:Float = lhs[3],
			m224:Float = lhs[7],
			m234:Float = lhs[11],
			m244:Float = lhs[15];

		this[0] = m111 * m211 + m112 * m221 + m113 * m231 + m114 * m241;
		this[1] = m111 * m212 + m112 * m222 + m113 * m232 + m114 * m242;
		this[2] = m111 * m213 + m112 * m223 + m113 * m233 + m114 * m243;
		this[3] = m111 * m214 + m112 * m224 + m113 * m234 + m114 * m244;

		this[4] = m121 * m211 + m122 * m221 + m123 * m231 + m124 * m241;
		this[5] = m121 * m212 + m122 * m222 + m123 * m232 + m124 * m242;
		this[6] = m121 * m213 + m122 * m223 + m123 * m233 + m124 * m243;
		this[7] = m121 * m214 + m122 * m224 + m123 * m234 + m124 * m244;

		this[8] = m131 * m211 + m132 * m221 + m133 * m231 + m134 * m241;
		this[9] = m131 * m212 + m132 * m222 + m133 * m232 + m134 * m242;
		this[10] = m131 * m213 + m132 * m223 + m133 * m233 + m134 * m243;
		this[11] = m131 * m214 + m132 * m224 + m133 * m234 + m134 * m244;

		this[12] = m141 * m211 + m142 * m221 + m143 * m231 + m144 * m241;
		this[13] = m141 * m212 + m142 * m222 + m143 * m232 + m144 * m242;
		this[14] = m141 * m213 + m142 * m223 + m143 * m233 + m144 * m243;
		this[15] = m141 * m214 + m142 * m224 + m143 * m234 + m144 * m244;
	}

	/**
		Appends rotation to the current matrix
		@param	degrees	A rotation value (in degrees)
		@param	axis	The coordinate position of the rotation axis
		@param	pivotPoint	(Optional) A pivot point to use in the rotation
	**/
	public function appendRotation(degrees:Float, axis:Vector4, pivotPoint:Vector4 = null):Void
	{
		var m = __getAxisRotation(axis.x, axis.y, axis.z, degrees);

		if (pivotPoint != null)
		{
			var p = pivotPoint;
			m.appendTranslation(p.x, p.y, p.z);
		}

		append(m);
	}

	/**
		Appends a scale value to the current matrix
		@param	xScale	The x scale to append
		@param	yScale	The y scale to append
		@param	zScale	The z scale to append
	**/
	public function appendScale(xScale:Float, yScale:Float, zScale:Float):Void
	{
		append(new Matrix4(new Float32Array([
			xScale, 0.0, 0.0, 0.0, 0.0, yScale, 0.0, 0.0, 0.0, 0.0, zScale, 0.0, 0.0, 0.0, 0.0, 1.0
		])));
	}

	/**
		Increases the position/translation of the current matrix
		@param	x	The x amount to offset the current position
		@param	y	The y amount to offset the current position
		@param	z	The z amount to offset the current position
	**/
	public function appendTranslation(x:Float, y:Float, z:Float):Void
	{
		this[12] = this[12] + x;
		this[13] = this[13] + y;
		this[14] = this[14] + z;
	}

	/**
		Creates a duplicate of the current `Matrix4`
		@return	A new `Matrix4` with the same values as the current matrix
	**/
	public function clone():Matrix4
	{
		return new Matrix4(new Float32Array(this));
	}

	/**
		Copies a column of data from a `Vector4` instance into the values of this matrix
		@param	column	The column to copy into (0, 1, 2 or 3)
		@param	vector	The `Vector4` copy from
	**/
	public function copyColumnFrom(column:Int, vector:Vector4):Void
	{
		switch (column)
		{
			case 0:
				this[0] = vector.x;
				this[1] = vector.y;
				this[2] = vector.z;
				this[3] = vector.w;

			case 1:
				this[4] = vector.x;
				this[5] = vector.y;
				this[6] = vector.z;
				this[7] = vector.w;

			case 2:
				this[8] = vector.x;
				this[9] = vector.y;
				this[10] = vector.z;
				this[11] = vector.w;

			case 3:
				this[12] = vector.x;
				this[13] = vector.y;
				this[14] = vector.z;
				this[15] = vector.w;

			default:
				Log.error("Column " + column + " out of bounds [0, ..., 3]");
		}
	}

	/**
		Copies a column of data from the current matrix into a `Vector4` instance
		@param	column	The column to copy (0, 1, 2 or 3)
		@param	vector	The `Vector4` copy to
	**/
	public function copyColumnTo(column:Int, vector:Vector4):Void
	{
		switch (column)
		{
			case 0:
				vector.x = this[0];
				vector.y = this[1];
				vector.z = this[2];
				vector.w = this[3];

			case 1:
				vector.x = this[4];
				vector.y = this[5];
				vector.z = this[6];
				vector.w = this[7];

			case 2:
				vector.x = this[8];
				vector.y = this[9];
				vector.z = this[10];
				vector.w = this[11];

			case 3:
				vector.x = this[12];
				vector.y = this[13];
				vector.z = this[14];
				vector.w = this[15];

			default:
				Log.error("Column " + column + " out of bounds [0, ..., 3]");
		}
	}

	/**
		Copies the values of another `Matrix4` into the current matrix
		@param	other	A `Matrix4` instance to copy from
	**/
	public function copyFrom(other:Matrix4):Void
	{
		this.set(cast other);
	}

	/**
		Copies a row of data from a `Vector4` instance into the values of this matrix
		@param	row	The row to copy into (0, 1, 2 or 3)
		@param	vector	The `Vector4` copy from
	**/
	public function copyRowFrom(row:Int, vector:Vector4)
	{
		switch (row)
		{
			case 0:
				this[0] = vector.x;
				this[4] = vector.y;
				this[8] = vector.z;
				this[12] = vector.w;

			case 1:
				this[1] = vector.x;
				this[5] = vector.y;
				this[9] = vector.z;
				this[13] = vector.w;

			case 2:
				this[2] = vector.x;
				this[6] = vector.y;
				this[10] = vector.z;
				this[14] = vector.w;

			case 3:
				this[3] = vector.x;
				this[7] = vector.y;
				this[11] = vector.z;
				this[15] = vector.w;

			default:
				Log.error("Row " + row + " out of bounds [0, ..., 3]");
		}
	}

	/**
		Copies a row of data from the current matrix into a `Vector4` instance
		@param	column	The row to copy (0, 1, 2 or 3)
		@param	vector	The `Vector4` copy to
	**/
	public function copyRowTo(row:Int, vector:Vector4):Void
	{
		switch (row)
		{
			case 0:
				vector.x = this[0];
				vector.y = this[4];
				vector.z = this[8];
				vector.w = this[12];

			case 1:
				vector.x = this[1];
				vector.y = this[5];
				vector.z = this[9];
				vector.w = this[13];

			case 2:
				vector.x = this[2];
				vector.y = this[6];
				vector.z = this[10];
				vector.w = this[14];

			case 3:
				vector.x = this[3];
				vector.y = this[7];
				vector.z = this[11];
				vector.w = this[15];

			default:
				Log.error("Row " + row + " out of bounds [0, ..., 3]");
		}
	}

	/**
		Resets the current matrix using two-dimensional transform values
		@param	a	A two-dimensional matrix a value
		@param	b	A two-dimensional matrix b value
		@param	c	A two-dimensional matrix c value
		@param	d	A two-dimensional matrix d value
		@param	tx	(Optional) A two-dimensional matrix tx value (default is 0)
		@param	ty	(Optional) A two-dimensional matrix ty value (default is 0)
	**/
	public function create2D(a:Float, b:Float, c:Float, d:Float, tx:Float = 0, ty:Float = 0):Void
	{
		this[0] = a;
		this[1] = b;
		this[2] = 0;
		this[3] = 0;

		this[4] = c;
		this[5] = d;
		this[6] = 0;
		this[7] = 0;

		this[8] = 0;
		this[9] = 0;
		this[10] = 1;
		this[11] = 0;

		this[12] = tx;
		this[13] = ty;
		this[14] = 0;
		this[15] = 1;
	}

	/**
		Initializes this matrix with values for an orthographic projection, useful in rendering
		@param	left	The left (or x0) coordinate for the projection
		@param	right	The right (or x1) coordinate for the projection
		@param	bottom	The bottom (or y0) coordinate for the projection
		@param	top	The top (or y1) coordinate for the projection
		@param	zNear	The near depth-clipping plane position
		@param	zFar	The far depth-clipping plane position
	**/
	public function createOrtho(left:Float, right:Float, bottom:Float, top:Float, zNear:Float, zFar:Float):Void
	{
		var sx = 1.0 / (right - left);
		var sy = 1.0 / (top - bottom);
		var sz = 1.0 / (zFar - zNear);

		this[0] = 2 * sx;
		this[1] = 0;
		this[2] = 0;
		this[3] = 0;

		this[4] = 0;
		this[5] = 2 * sy;
		this[6] = 0;
		this[7] = 0;

		this[8] = 0;
		this[9] = 0;
		this[10] = -2 * sz;
		this[11] = 0;

		this[12] = -(left + right) * sx;
		this[13] = -(bottom + top) * sy;
		this[14] = -(zNear + zFar) * sz;
		this[15] = 1;
	}

	/**
	 * Returns the transformation matrix's translation, rotation, and scale settings as a Vector of three Vector4 objects.
	 */
	/*public function decompose(?orientationStyle:Orientation3D):Vector<Vector4> {

		if (orientationStyle==null)
			orientationStyle = Orientation3D.EULER_ANGLES;

		var vec = new Vector<Vector4>();
		var m = clone();
		var mr = m.copy();

		var pos = new Vector4 (mr[12], mr[13], mr[14]);
		mr[12] = 0;
		mr[13] = 0;
		mr[14] = 0;

		var scale = new Vector4 ();

		scale.x = Math.sqrt(mr[0] * mr[0] + mr[1] * mr[1] + mr[2] * mr[2]);
		scale.y = Math.sqrt(mr[4] * mr[4] + mr[5] * mr[5] + mr[6] * mr[6]);
		scale.z = Math.sqrt(mr[8] * mr[8] + mr[9] * mr[9] + mr[10] * mr[10]);

		if (mr[0] * (mr[5] * mr[10] - mr[6] * mr[9]) - mr[1] * (mr[4] * mr[10] - mr[6] * mr[8]) + mr[2] * (mr[4] * mr[9] - mr[5] * mr[8]) < 0) {

			scale.z = -scale.z;

		}

		mr[0] /= scale.x;
		mr[1] /= scale.x;
		mr[2] /= scale.x;
		mr[4] /= scale.y;
		mr[5] /= scale.y;
		mr[6] /= scale.y;
		mr[8] /= scale.z;
		mr[9] /= scale.z;
		mr[10] /= scale.z;

		var rot = new Vector4 ();
		switch (orientationStyle) {

			case Orientation3D.AXIS_ANGLE:
				rot.w = Math.acos((mr[0] + mr[5] + mr[10] - 1) / 2);

				var len = Math.sqrt((mr[6] - mr[9]) * (mr[6] - mr[9]) + (mr[8] - mr[2]) * (mr[8] - mr[2]) + (mr[1] - mr[4]) * (mr[1] - mr[4]));
				rot.x = (mr[6] - mr[9]) / len;
				rot.y = (mr[8] - mr[2]) / len;
				rot.z = (mr[1] - mr[4]) / len;

			case Orientation3D.QUATERNION:
				var tr = mr[0] + mr[5] + mr[10];

				if (tr > 0) {
					rot.w = Math.sqrt(1 + tr) / 2;

					rot.x = (mr[6] - mr[9]) / (4 * rot.w);
					rot.y = (mr[8] - mr[2]) / (4 * rot.w);
					rot.z = (mr[1] - mr[4]) / (4 * rot.w);
				} else if ((mr[0] > mr[5]) && (mr[0] > mr[10])) {
					rot.x = Math.sqrt(1 + mr[0] - mr[5] - mr[10]) / 2;

					rot.w = (mr[6] - mr[9]) / (4 * rot.x);
					rot.y = (mr[1] + mr[4]) / (4 * rot.x);
					rot.z = (mr[8] + mr[2]) / (4 * rot.x);
				} else if (mr[5] > mr[10]) {
					rot.y = Math.sqrt(1 + mr[5] - mr[0] - mr[10]) / 2;

					rot.x = (mr[1] + mr[4]) / (4 * rot.y);
					rot.w = (mr[8] - mr[2]) / (4 * rot.y);
					rot.z = (mr[6] + mr[9]) / (4 * rot.y);
				} else {
					rot.z = Math.sqrt(1 + mr[10] - mr[0] - mr[5]) / 2;

					rot.x = (mr[8] + mr[2]) / (4 * rot.z);
					rot.y = (mr[6] + mr[9]) / (4 * rot.z);
					rot.w = (mr[1] - mr[4]) / (4 * rot.z);
				}

			case Orientation3D.EULER_ANGLES:
				rot.y = Math.asin(-mr[2]);

				if (mr[2] != 1 && mr[2] != -1) {
					rot.x = Math.atan2(mr[6], mr[10]);
					rot.z = Math.atan2(mr[1], mr[0]);
				} else {
					rot.z = 0;
					rot.x = Math.atan2(mr[4], mr[5]);
				}
		}

		vec.push(pos);
		vec.push(rot);
		vec.push(scale);

		return vec;

	}*/
	/**
		Transforms a vector using this matrix, ignoring the translation of the matrix
		@param	result	(Optional) An existing `Vector4` instance to fill with the result
		@param	v	A `Vector4` instance to transform
	**/
	public function deltaTransformVector(v:Vector4, result:Vector4 = null):Vector4
	{
		if (result == null) result = new Vector4();
		var x = v.x, y = v.y, z = v.z;
		result.x = (x * this[0] + y * this[4] + z * this[8] + this[3]);
		result.y = (x * this[1] + y * this[5] + z * this[9] + this[7]);
		result.z = (x * this[2] + y * this[6] + z * this[10] + this[11]);
		return result;
	}

	@:from public static function fromMatrix3(matrix3:Matrix3):Matrix4
	{
		var mat = new Matrix4();
		mat.create2D(matrix3.a, matrix3.b, matrix3.c, matrix3.d, matrix3.tx, matrix3.ty);
		return mat;
	}

	/**
		Resets the current matrix using default identity values
	**/
	public function identity():Void
	{
		this[0] = 1;
		this[1] = 0;
		this[2] = 0;
		this[3] = 0;
		this[4] = 0;
		this[5] = 1;
		this[6] = 0;
		this[7] = 0;
		this[8] = 0;
		this[9] = 0;
		this[10] = 1;
		this[11] = 0;
		this[12] = 0;
		this[13] = 0;
		this[14] = 0;
		this[15] = 1;
	}

	/**
		Interpolates from one `Matrix4` instance to another, given a percentage between the two
		@param	thisMat	The first `Matrix4` object to start from
		@param	toMat	The second `Matrix4` object to interpolate toward
		@param	percent	The percentage value to interpolate by
		@param	result	(Optional) A `Matrix4` instance to use when returning the result
		@return	A `Matrix4` with the resulting value
	**/
	public static function interpolate(thisMat:Matrix4, toMat:Matrix4, percent:Float, result:Matrix4 = null):Matrix4
	{
		if (result == null) result = new Matrix4();

		for (i in 0...16)
		{
			result[i] = thisMat[i] + (toMat[i] - thisMat[i]) * percent;
		}

		return result;
	}

	/**
		Interpolates the current matrix toward another matrix, resetting the values of the current matrix
		@param	toMat	The second `Matrix4` object to interpolate toward
		@param	percetn	The percentage value to interpolate by
	**/
	public function interpolateTo(toMat:Matrix4, percent:Float):Void
	{
		for (i in 0...16)
		{
			this[i] = this[i] + (toMat[i] - this[i]) * percent;
		}
	}

	/**
		Attempts to invert the current matrix, so long as the determinant is greater than zero
		@return	Whether the `invert` operation was successful
	**/
	public function invert():Bool
	{
		var d = determinant;
		var invertable = Math.abs(d) > 0.00000000001;

		if (invertable)
		{
			d = 1 / d;

			var m11:Float = this[0];
			var m21:Float = this[4];
			var m31:Float = this[8];
			var m41:Float = this[12];
			var m12:Float = this[1];
			var m22:Float = this[5];
			var m32:Float = this[9];
			var m42:Float = this[13];
			var m13:Float = this[2];
			var m23:Float = this[6];
			var m33:Float = this[10];
			var m43:Float = this[14];
			var m14:Float = this[3];
			var m24:Float = this[7];
			var m34:Float = this[11];
			var m44:Float = this[15];

			this[0] = d * (m22 * (m33 * m44 - m43 * m34) - m32 * (m23 * m44 - m43 * m24) + m42 * (m23 * m34 - m33 * m24));
			this[1] = -d * (m12 * (m33 * m44 - m43 * m34) - m32 * (m13 * m44 - m43 * m14) + m42 * (m13 * m34 - m33 * m14));
			this[2] = d * (m12 * (m23 * m44 - m43 * m24) - m22 * (m13 * m44 - m43 * m14) + m42 * (m13 * m24 - m23 * m14));
			this[3] = -d * (m12 * (m23 * m34 - m33 * m24) - m22 * (m13 * m34 - m33 * m14) + m32 * (m13 * m24 - m23 * m14));
			this[4] = -d * (m21 * (m33 * m44 - m43 * m34) - m31 * (m23 * m44 - m43 * m24) + m41 * (m23 * m34 - m33 * m24));
			this[5] = d * (m11 * (m33 * m44 - m43 * m34) - m31 * (m13 * m44 - m43 * m14) + m41 * (m13 * m34 - m33 * m14));
			this[6] = -d * (m11 * (m23 * m44 - m43 * m24) - m21 * (m13 * m44 - m43 * m14) + m41 * (m13 * m24 - m23 * m14));
			this[7] = d * (m11 * (m23 * m34 - m33 * m24) - m21 * (m13 * m34 - m33 * m14) + m31 * (m13 * m24 - m23 * m14));
			this[8] = d * (m21 * (m32 * m44 - m42 * m34) - m31 * (m22 * m44 - m42 * m24) + m41 * (m22 * m34 - m32 * m24));
			this[9] = -d * (m11 * (m32 * m44 - m42 * m34) - m31 * (m12 * m44 - m42 * m14) + m41 * (m12 * m34 - m32 * m14));
			this[10] = d * (m11 * (m22 * m44 - m42 * m24) - m21 * (m12 * m44 - m42 * m14) + m41 * (m12 * m24 - m22 * m14));
			this[11] = -d * (m11 * (m22 * m34 - m32 * m24) - m21 * (m12 * m34 - m32 * m14) + m31 * (m12 * m24 - m22 * m14));
			this[12] = -d * (m21 * (m32 * m43 - m42 * m33) - m31 * (m22 * m43 - m42 * m23) + m41 * (m22 * m33 - m32 * m23));
			this[13] = d * (m11 * (m32 * m43 - m42 * m33) - m31 * (m12 * m43 - m42 * m13) + m41 * (m12 * m33 - m32 * m13));
			this[14] = -d * (m11 * (m22 * m43 - m42 * m23) - m21 * (m12 * m43 - m42 * m13) + m41 * (m12 * m23 - m22 * m13));
			this[15] = d * (m11 * (m22 * m33 - m32 * m23) - m21 * (m12 * m33 - m32 * m13) + m31 * (m12 * m23 - m22 * m13));
		}

		return invertable;
	}

	/**
		Sets the matrix values as a transformation orientated toward a certain vector position
		@param	pos	A target vector position in absolute coordinates
		@param	at	(Optional) A vector relative to this matrix which defines the current direction
		@param	up	(Optional) A vector relative to this matrix which defines the "up" direction
	**/
	public function pointAt(pos:Vector4, at:Vector4 = null, up:Vector4 = null):Void
	{
		// TODO: This implementation is broken

		if (at == null)
		{
			at = new Vector4(0, 0, 1);
		}

		if (up == null)
		{
			up = new Vector4(0, 1, 0);
		}

		var dir = pos.subtract(at);
		var vup = up.clone();
		var right:Vector4;

		dir.normalize();
		vup.normalize();

		var dir2 = dir.clone();
		dir2.scaleBy(vup.dotProduct(dir));

		vup = vup.subtract(dir2);

		if (vup.length > 0)
		{
			vup.normalize();
		}
		else
		{
			if (dir.x != 0)
			{
				vup = new Vector4(-dir.y, dir.x, 0);
			}
			else
			{
				vup = new Vector4(1, 0, 0);
			}
		}

		right = vup.crossProduct(dir);
		right.normalize();

		this[0] = right.x;
		this[4] = right.y;
		this[8] = right.z;
		this[12] = 0.0;
		this[1] = vup.x;
		this[5] = vup.y;
		this[9] = vup.z;
		this[13] = 0.0;
		this[2] = dir.x;
		this[6] = dir.y;
		this[10] = dir.z;
		this[14] = 0.0;
		this[3] = pos.x;
		this[7] = pos.y;
		this[11] = pos.z;
		this[15] = 1.0;
	}

	/**
		Prepends a right-hand matrix to the current matrix
		@param	rhx	A right-hand `Matrix4` to append
	**/
	public function prepend(rhs:Matrix4):Void
	{
		var m111:Float = rhs[0],
			m121:Float = rhs[4],
			m131:Float = rhs[8],
			m141:Float = rhs[12],
			m112:Float = rhs[1],
			m122:Float = rhs[5],
			m132:Float = rhs[9],
			m142:Float = rhs[13],
			m113:Float = rhs[2],
			m123:Float = rhs[6],
			m133:Float = rhs[10],
			m143:Float = rhs[14],
			m114:Float = rhs[3],
			m124:Float = rhs[7],
			m134:Float = rhs[11],
			m144:Float = rhs[15],
			m211:Float = this[0],
			m221:Float = this[4],
			m231:Float = this[8],
			m241:Float = this[12],
			m212:Float = this[1],
			m222:Float = this[5],
			m232:Float = this[9],
			m242:Float = this[13],
			m213:Float = this[2],
			m223:Float = this[6],
			m233:Float = this[10],
			m243:Float = this[14],
			m214:Float = this[3],
			m224:Float = this[7],
			m234:Float = this[11],
			m244:Float = this[15];

		this[0] = m111 * m211 + m112 * m221 + m113 * m231 + m114 * m241;
		this[1] = m111 * m212 + m112 * m222 + m113 * m232 + m114 * m242;
		this[2] = m111 * m213 + m112 * m223 + m113 * m233 + m114 * m243;
		this[3] = m111 * m214 + m112 * m224 + m113 * m234 + m114 * m244;

		this[4] = m121 * m211 + m122 * m221 + m123 * m231 + m124 * m241;
		this[5] = m121 * m212 + m122 * m222 + m123 * m232 + m124 * m242;
		this[6] = m121 * m213 + m122 * m223 + m123 * m233 + m124 * m243;
		this[7] = m121 * m214 + m122 * m224 + m123 * m234 + m124 * m244;

		this[8] = m131 * m211 + m132 * m221 + m133 * m231 + m134 * m241;
		this[9] = m131 * m212 + m132 * m222 + m133 * m232 + m134 * m242;
		this[10] = m131 * m213 + m132 * m223 + m133 * m233 + m134 * m243;
		this[11] = m131 * m214 + m132 * m224 + m133 * m234 + m134 * m244;

		this[12] = m141 * m211 + m142 * m221 + m143 * m231 + m144 * m241;
		this[13] = m141 * m212 + m142 * m222 + m143 * m232 + m144 * m242;
		this[14] = m141 * m213 + m142 * m223 + m143 * m233 + m144 * m243;
		this[15] = m141 * m214 + m142 * m224 + m143 * m234 + m144 * m244;
	}

	/**
		Prepends rotation to this matrix
		@param	degrees	The rotation amount in degrees
		@param	axis	The rotation axis
		@param	pivotPoint	(Optional) A pivot point for the rotation
	**/
	public function prependRotation(degrees:Float, axis:Vector4, pivotPoint:Vector4 = null):Void
	{
		var m = __getAxisRotation(axis.x, axis.y, axis.z, degrees);

		if (pivotPoint != null)
		{
			var p = pivotPoint;
			m.appendTranslation(p.x, p.y, p.z);
		}

		prepend(m);
	}

	/**
		Prepends scale to this matrix
		@param	xScale	An x scale value
		@param	yScale	A y scale value
		@param	zScale	A z scale value
	**/
	public function prependScale(xScale:Float, yScale:Float, zScale:Float):Void
	{
		prepend(new Matrix4(new Float32Array([
			xScale, 0.0, 0.0, 0.0, 0.0, yScale, 0.0, 0.0, 0.0, 0.0, zScale, 0.0, 0.0, 0.0, 0.0, 1.0
		])));
	}

	/**
		Prepends translation values to this matrix
		@param	x	An x translation value
		@param	y	A y translation value
		@param	z	A z translation value
	**/
	public function prependTranslation(x:Float, y:Float, z:Float):Void
	{
		var m = new Matrix4();
		m.position = new Vector4(x, y, z);
		prepend(m);
	}

	/*public function recompose (components:Vector<Vector4>, ?orientationStyle:Orientation3D ):Bool {

		if (components.length < 3 || components[2].x == 0 || components[2].y == 0 || components[2].z == 0)
			return false;

		if (orientationStyle == null)
			orientationStyle = Orientation3D.EULER_ANGLES;

		identity();

		var scale = [];
		scale[0] = scale[1] = scale[2] = components[2].x;
		scale[4] = scale[5] = scale[6] = components[2].y;
		scale[8] = scale[9] = scale[10] = components[2].z;

		switch (orientationStyle) {

			case Orientation3D.EULER_ANGLES:
				var cx = Math.cos(components[1].x);
				var cy = Math.cos(components[1].y);
				var cz = Math.cos(components[1].z);
				var sx = Math.sin(components[1].x);
				var sy = Math.sin(components[1].y);
				var sz = Math.sin(components[1].z);

				this[0]=cy*cz*scale[0];
				this[1]=cy*sz*scale[1];
				this[2]=- sy*scale[2];
				this[3]=0;
				this[4] = (sx*sy*cz-cx*sz)*scale[4];
				this[5] = (sx*sy*sz+cx*cz)*scale[5];
				this[6]=sx*cy*scale[6];
				this[7]=0;
				this[8] = (cx*sy*cz+sx*sz)*scale[8];
				this[9] = (cx*sy*sz-sx*cz)*scale[9];
				this[10]=cx*cy*scale[10];
				this[11]=0;
				this[12]=components[0].x;
				this[13]=components[0].y;
				this[14]=components[0].z;
				this[15]=1;

			default:

				var x = components[1].x;
				var y = components[1].y;
				var z = components[1].z;
				var w = components[1].w;
				if (Type.enumEq(orientationStyle, Orientation3D.AXIS_ANGLE)) {
					x *= Math.sin(w/2);
					y *= Math.sin(w/2);
					z *= Math.sin(w/2);
					w = Math.cos(w/2);
				}

				this[0] = (1-2*y*y-2*z*z)*scale[0];
				this[1] = (2*x*y+2*w*z)*scale[1];
				this[2] = (2*x*z-2*w*y)*scale[2];
				this[3] = 0;
				this[4] = (2*x*y-2*w*z)*scale[4];
				this[5] = (1-2*x*x-2*z*z)*scale[5];
				this[6] = (2*y*z+2*w*x)*scale[6];
				this[7] = 0;
				this[8] = (2*x*z+2*w*y)*scale[8];
				this[9] = (2*y*z-2*w*x)*scale[9];
				this[10] = (1-2*x*x-2*y*y)*scale[10];
				this[11] = 0;
				this[12] = components[0].x;
				this[13] = components[0].y;
				this[14] = components[0].z;
				this[15] = 1;
		}

		if (components[2].x == 0)
			this[0] = 1e-15;
		if (components[2].y == 0)
			this[5] = 1e-15;
		if (components[2].z == 0)
			this[10] = 1e-15;

		return !(components[2].x == 0 || components[2].y == 0 || components[2].y == 0);
	}*/
	/**
		Transforms a `Vector4` instance using the current matrix
		@param	result	(Optional) An existing `Vector2` instance to fill with the result
		@return	The resulting `Vector4` instance
	**/
	public function transformVector(v:Vector4, result:Vector4 = null):Vector4
	{
		if (result == null) result = new Vector4();
		var x = v.x, y = v.y, z = v.z;
		result.x = (x * this[0] + y * this[4] + z * this[8] + this[12]);
		result.y = (x * this[1] + y * this[5] + z * this[9] + this[13]);
		result.z = (x * this[2] + y * this[6] + z * this[10] + this[14]);
		result.w = (x * this[3] + y * this[7] + z * this[11] + this[15]);
		return result;
	}

	/**
		Transforms a series of [x, y, z] value pairs at once
		@param	ain	An input `Float32Array` to transform
		@param	aout	An output `Float32Array` to write to
	**/
	public function transformVectors(ain:Float32Array, aout:Float32Array):Void
	{
		var i = 0;
		var x:Float, y:Float, z:Float;

		while (i + 3 <= ain.length)
		{
			x = ain[i];
			y = ain[i + 1];
			z = ain[i + 2];

			aout[i] = x * this[0] + y * this[4] + z * this[8] + this[12];
			aout[i + 1] = x * this[1] + y * this[5] + z * this[9] + this[13];
			aout[i + 2] = x * this[2] + y * this[6] + z * this[10] + this[14];

			i += 3;
		}
	}

	/**
		Transposes the current matrix
	**/
	public function transpose():Void
	{
		__swap(1, 4);
		__swap(2, 8);
		__swap(3, 12);
		__swap(6, 9);
		__swap(7, 13);
		__swap(11, 14);
	}

	@:noCompletion private function __getAxisRotation(x:Float, y:Float, z:Float, degrees:Float):Matrix4
	{
		var m = new Matrix4();

		var a1 = new Vector4(x, y, z);
		var rad = -degrees * (Math.PI / 180);
		var c = Math.cos(rad);
		var s = Math.sin(rad);
		var t = 1.0 - c;

		m[0] = c + a1.x * a1.x * t;
		m[5] = c + a1.y * a1.y * t;
		m[10] = c + a1.z * a1.z * t;

		var tmp1 = a1.x * a1.y * t;
		var tmp2 = a1.z * s;
		m[4] = tmp1 + tmp2;
		m[1] = tmp1 - tmp2;
		tmp1 = a1.x * a1.z * t;
		tmp2 = a1.y * s;
		m[8] = tmp1 - tmp2;
		m[2] = tmp1 + tmp2;
		tmp1 = a1.y * a1.z * t;
		tmp2 = a1.x * s;
		m[9] = tmp1 + tmp2;
		m[6] = tmp1 - tmp2;

		return m;
	}

	@:noCompletion private inline function __swap(a:Int, b:Int):Void
	{
		var temp = this[a];
		this[a] = this[b];
		this[b] = temp;
	}

	// Getters & Setters
	@:noCompletion private function get_determinant():Float
	{
		return 1 * ((this[0] * this[5] - this[4] * this[1]) * (this[10] * this[15] - this[14] * this[11])
			- (this[0] * this[9] - this[8] * this[1]) * (this[6] * this[15] - this[14] * this[7])
			+ (this[0] * this[13] - this[12] * this[1]) * (this[6] * this[11] - this[10] * this[7])
			+ (this[4] * this[9] - this[8] * this[5]) * (this[2] * this[15] - this[14] * this[3])
			- (this[4] * this[13] - this[12] * this[5]) * (this[2] * this[11] - this[10] * this[3])
			+ (this[8] * this[13] - this[12] * this[9]) * (this[2] * this[7] - this[6] * this[3]));
	}

	@:noCompletion private function get_position():Vector4
	{
		return new Vector4(this[12], this[13], this[14]);
	}

	@:noCompletion private function set_position(val:Vector4):Vector4
	{
		this[12] = val.x;
		this[13] = val.y;
		this[14] = val.z;
		return val;
	}

	@:dox(hide) @:noCompletion @:arrayAccess public function get(index:Int):Float
	{
		return this[index];
	}

	@:dox(hide) @:noCompletion @:arrayAccess public function set(index:Int, value:Float):Float
	{
		this[index] = value;
		return value;
	}
}
