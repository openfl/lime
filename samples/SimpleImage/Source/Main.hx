package;


import lime.app.Application;
import lime.graphics.opengl.*;
import lime.graphics.Image;
import lime.graphics.RenderContext;
import lime.math.Matrix4;
import lime.utils.Float32Array;
import lime.utils.GLUtils;
import lime.Assets;


class Main extends Application {
	
	
	private var buffer:GLBuffer;
	private var image:Image;
	private var matrixUniform:GLUniformLocation;
	private var program:GLProgram;
	private var texture:GLTexture;
	private var textureAttribute:Int;
	private var vertexAttribute:Int;
	
	
	public function new () {
		
		super ();
		
	}
	
	
	public override function init (context:RenderContext):Void {
		
		image = Assets.getImage ("assets/lime.png");
		
		switch (context) {
			
			case CANVAS (context):
				
				context.fillStyle = "#" + StringTools.hex (config.background, 6);
				context.fillRect (0, 0, window.width, window.height);
				context.drawImage (image.src, 0, 0, image.width, image.height);
			
			case DOM (element):
				
				element.style.backgroundColor = "#" + StringTools.hex (config.background, 6);
				element.appendChild (image.src);
			
			case FLASH (sprite):
				
				#if flash
				var bitmap = new flash.display.Bitmap (image.src);
				sprite.addChild (bitmap);
				#end
			
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
					
					#if !desktop
					"precision mediump float;" +
					#end
					"varying vec2 vTexCoord;
					uniform sampler2D uImage0;
					
					void main(void)
					{
						gl_FragColor = texture2D (uImage0, vTexCoord);
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
				
				var data = [
					
					image.width, image.height, 0, 1, 1,
					0, image.height, 0, 0, 1,
					image.width, 0, 0, 1, 0,
					0, 0, 0, 0, 0
					
				];
				
				buffer = gl.createBuffer ();
				gl.bindBuffer (gl.ARRAY_BUFFER, buffer);
				gl.bufferData (gl.ARRAY_BUFFER, new Float32Array (cast data), gl.STATIC_DRAW);
				gl.bindBuffer (gl.ARRAY_BUFFER, null);
				
				texture = gl.createTexture ();
				gl.bindTexture (gl.TEXTURE_2D, texture);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
				#if js
				gl.texImage2D (gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image.src);
				#else
				gl.texImage2D (gl.TEXTURE_2D, 0, gl.RGBA, image.buffer.width, image.buffer.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, image.data);
				#end
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
				gl.bindTexture (gl.TEXTURE_2D, null);
			
			default:
			
		}
		
	}
	
	
	public override function render (context:RenderContext):Void {
		
		switch (context) {
			
			case OPENGL (gl):
				
				gl.viewport (0, 0, window.width, window.height);
				
				var r = ((config.background >> 16) & 0xFF) / 0xFF;
				var g = ((config.background >> 8) & 0xFF) / 0xFF;
				var b = (config.background & 0xFF) / 0xFF;
				var a = ((config.background >> 24) & 0xFF) / 0xFF;
				
				gl.clearColor (r, g, b, a);
				gl.clear (gl.COLOR_BUFFER_BIT);
				
				var matrix = Matrix4.createOrtho (0, window.width, window.height, 0, -1000, 1000);
				gl.uniformMatrix4fv (matrixUniform, false, matrix);
				
				gl.activeTexture (gl.TEXTURE0);
				gl.bindTexture (gl.TEXTURE_2D, texture);
				
				#if desktop
				gl.enable (gl.TEXTURE_2D);
				#end
				
				gl.bindBuffer (gl.ARRAY_BUFFER, buffer);
				gl.vertexAttribPointer (vertexAttribute, 3, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 0);
				gl.vertexAttribPointer (textureAttribute, 2, gl.FLOAT, false, 5 * Float32Array.BYTES_PER_ELEMENT, 3 * Float32Array.BYTES_PER_ELEMENT);
				
				gl.drawArrays (gl.TRIANGLE_STRIP, 0, 4);
				
			default:
			
		}
		
	}
	
	
}