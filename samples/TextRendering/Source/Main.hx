package;


import lime.app.Application;
import lime.math.Matrix4;
import lime.graphics.*;
import lime.graphics.opengl.*;
import lime.utils.*;


class TextField {


	private var vertexBuffer:GLBuffer;
	private var indexBuffer:GLBuffer;
	private var texture:GLTexture;
	private var numTriangles:Int;
	private var size:Int;
	private var text:String;
	private var image:ImageBuffer;


	public function new (text:String, size:Int, textFormat:TextFormat, font:Font, context:RenderContext, x:Float=0, y:Float=0) {

		font.loadGlyphs (size, text);
		image = font.createImage ();
		this.text = text;
		this.size = size;

		init (context, textFormat, font, x, y);

	}


	public function init (context:RenderContext, textFormat:TextFormat, font:Font, x:Float, y:Float) {

		var points = textFormat.fromString (font, size, text);

		switch (context) {

			// case CANVAS (context):

			// 	context.fillStyle = "#" + StringTools.hex (config.background, 6);
			// 	context.fillRect (0, 0, window.width, window.height);
			// 	context.drawImage (image.src, 0, 0, image.width, image.height);

			// case DOM (element):

			// 	#if js
			// 	element.style.backgroundColor = "#" + StringTools.hex (config.background, 6);
			// 	element.appendChild (image);
			// 	#end

			case FLASH (sprite):

				#if flash
				var bitmap = new flash.display.Bitmap (image.src);
				sprite.addChild (bitmap);
				#end

			case OPENGL (gl):

				var vertices = new Array<Float>();
				var indices = new Array<Int>();
				var left, top, right, bottom;
				var glyphRects = font.glyphs.get (size);
				if (glyphRects == null) return;

				if (textFormat.direction == RightToLeft) {

					var width = 0.0;

					for (p in points) {

						if (!glyphRects.exists(p.codepoint)) continue;
						var glyph = glyphRects.get(p.codepoint);

						width += p.advance.x;

					}

					x -= width;

				}

				for (p in points) {

					if (!glyphRects.exists(p.codepoint)) continue;
					var glyph = glyphRects.get(p.codepoint);

					left   = glyph.x / image.width;
					top    = glyph.y / image.height;
					right  = left + glyph.width / image.width;
					bottom = top + glyph.height / image.height;

					var pointLeft = x + p.offset.x + glyph.xOffset;
					var pointTop = y + p.offset.y - glyph.yOffset;
					var pointRight = pointLeft + glyph.width;
					var pointBottom = pointTop + glyph.height;

					vertices.push(pointRight);
					vertices.push(pointBottom);
					vertices.push(right);
					vertices.push(bottom);

					vertices.push(pointLeft);
					vertices.push(pointBottom);
					vertices.push(left);
					vertices.push(bottom);

					vertices.push(pointRight);
					vertices.push(pointTop);
					vertices.push(right);
					vertices.push(top);

					vertices.push(pointLeft);
					vertices.push(pointTop);
					vertices.push(left);
					vertices.push(top);

					var i = Std.int(indices.length / 6) * 4;
					indices.push(i);
					indices.push(i+1);
					indices.push(i+2);
					indices.push(i+1);
					indices.push(i+2);
					indices.push(i+3);

					x += p.advance.x;
					y -= p.advance.y; // flip because of y-axis direction
				}
				numTriangles = indices.length;

				vertexBuffer = gl.createBuffer ();
				gl.bindBuffer (gl.ARRAY_BUFFER, vertexBuffer);
				gl.bufferData (gl.ARRAY_BUFFER, new Float32Array (cast vertices), gl.STATIC_DRAW);

				indexBuffer = gl.createBuffer ();
				gl.bindBuffer (gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
				gl.bufferData (gl.ELEMENT_ARRAY_BUFFER, new UInt8Array (cast indices), gl.STATIC_DRAW);

				var format = image.bitsPerPixel == 1 ? GL.ALPHA : GL.RGBA;
				texture = gl.createTexture ();
				gl.bindTexture (gl.TEXTURE_2D, texture);
				#if js
				gl.texImage2D (gl.TEXTURE_2D, 0, format, format, gl.UNSIGNED_BYTE, image.src);
				#else
				gl.texImage2D (gl.TEXTURE_2D, 0, format, image.width, image.height, 0, format, gl.UNSIGNED_BYTE, image.data);
				#end
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

			default:

		}

	}


	public function render (context:RenderContext, vertexAttribute:Int, textureAttribute:Int) {

		switch (context) {

			case OPENGL (gl):

				gl.activeTexture (gl.TEXTURE0);
				gl.bindTexture (gl.TEXTURE_2D, texture);

				gl.bindBuffer (gl.ARRAY_BUFFER, vertexBuffer);
				gl.vertexAttribPointer (vertexAttribute, 2, gl.FLOAT, false, 4 * Float32Array.BYTES_PER_ELEMENT, 0);
				gl.vertexAttribPointer (textureAttribute, 2, gl.FLOAT, false, 4 * Float32Array.BYTES_PER_ELEMENT, 2 * Float32Array.BYTES_PER_ELEMENT);

				gl.bindBuffer (gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
				gl.drawElements (gl.TRIANGLES, numTriangles, gl.UNSIGNED_BYTE, 0);

			default:

		}

	}

}


class Main extends Application {


	private var matrixUniform:GLUniformLocation;
	private var program:GLProgram;
	private var textureAttribute:Int;
	private var vertexAttribute:Int;
	private var textFields:Array<TextField>;


	public function new () {

		super ();
		textFields = new Array<TextField> ();

	}


	public override function init (context:RenderContext):Void {

		textFields.push(new TextField ("صِف خَلقَ خَودِ كَمِثلِ الشَمسِ إِذ بَزَغَت — يَحظى الضَجيعُ بِها نَجلاءَ مِعطارِ", 24,
			new TextFormat (RightToLeft, ScriptArabic, "ar"),
			new Font ("assets/amiri-regular.ttf"),
			context, window.width - 20, 100));

		textFields.push(new TextField ("The quick brown fox jumps over the lazy dog.", 16,
			new TextFormat (LeftToRight, ScriptLatin, "en"),
			new Font ("assets/amiri-regular.ttf"),
			context, 20, 20));

		textFields.push(new TextField ("懶惰的姜貓", 32,
			new TextFormat (TopToBottom, ScriptHan, "zh"),
			new Font ("assets/fireflysung.ttf"),
			context, 50, 150));

		switch (context) {

			case OPENGL (gl):

				var vertexSource =

					"attribute vec4 aPosition;
					attribute vec2 aTexCoord;
					varying vec2 vTexCoord;

					uniform mat4 uMatrix;

					void main(void) {

						vTexCoord = aTexCoord;
						gl_Position = uMatrix * aPosition;

					}";

				var fragmentSource =

					"#ifdef GL_ES
					precision mediump float;
					#endif
					varying vec2 vTexCoord;
					uniform sampler2D uImage0;

					void main(void)
					{
						gl_FragColor = vec4 (0, 0, 0, texture2D (uImage0, vTexCoord).a);
					}";

				program = GLUtils.createProgram (vertexSource, fragmentSource);
				gl.useProgram (program);

				vertexAttribute = gl.getAttribLocation (program, "aPosition");
				textureAttribute = gl.getAttribLocation (program, "aTexCoord");
				matrixUniform = gl.getUniformLocation (program, "uMatrix");
				var imageUniform = gl.getUniformLocation (program, "uImage0");

				gl.enableVertexAttribArray (vertexAttribute);
				gl.enableVertexAttribArray (textureAttribute);
				gl.uniform1i (imageUniform, 0);

				#if desktop
				gl.enable (gl.TEXTURE_2D);
				#end

				gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
				gl.enable(gl.BLEND);

				gl.viewport (0, 0, window.width, window.height);

			default:

		}

	}


	public override function render (context:RenderContext):Void {

		switch (context) {

			case OPENGL (gl):

				var r = ((config.background >> 16) & 0xFF) / 0xFF;
				var g = ((config.background >> 8) & 0xFF) / 0xFF;
				var b = (config.background & 0xFF) / 0xFF;
				var a = ((config.background >> 24) & 0xFF) / 0xFF;

				gl.clearColor (r, g, b, a);
				gl.clear (gl.COLOR_BUFFER_BIT);

				var matrix = Matrix4.createOrtho (0, window.width, window.height, 0, -10, 10);
				gl.uniformMatrix4fv (matrixUniform, false, matrix);

				for (i in 0...textFields.length) {

					textFields[i].render (context, vertexAttribute, textureAttribute);

				}

			default:

		}

	}


}
