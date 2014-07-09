package;


import lime.app.Application;
import lime.geom.Matrix4;
import lime.graphics.Image;
import lime.graphics.GLBuffer;
import lime.graphics.GLProgram;
import lime.graphics.GLRenderContext;
import lime.graphics.GLTexture;
import lime.graphics.RenderContext;
import lime.utils.Float32Array;
import lime.Assets;


#if html5
@:access(lime.graphics.GL)
#end


class Main extends Application {
	
	
	private var initialized:Bool;
	
	private var shaderProgram:GLProgram;
	private var texCoordBuffer:GLBuffer;
	private var texture:GLTexture;
	private var vertexBuffer:GLBuffer;
	
	
	public function new () {
		
		super ();
		
	}
	
	
	private function initialize (context:RenderContext):Void {
		
		switch (context) {
			
			case DOM (element):
				
				#if js
				var image = new js.html.Image ();
				image.src = Assets.getPath ("assets/lime.png");
				element.style.backgroundColor = "#" + StringTools.hex (config.background, 6);
				element.appendChild (image);
				#end
			
			case OPENGL (gl):
				
				// Initialize shaders
				
				var vertexShaderSource = 
					
					"attribute vec4 aPosition;
					attribute vec2 aTexCoord;
					varying vec2 vTexCoord;
					
					uniform mat4 uMatrix;
					
					void main(void) {
						
						vTexCoord = aTexCoord;
						gl_Position = uMatrix * aPosition;
						
					}";
				
				var vertexShader = gl.createShader (gl.VERTEX_SHADER);
				gl.shaderSource (vertexShader, vertexShaderSource);
				gl.compileShader (vertexShader);
				
				if (gl.getShaderParameter (vertexShader, gl.COMPILE_STATUS) == 0) {
					
					throw "Error compiling vertex shader";
					
				}
				
				var fragmentShaderSource = 
					
					#if !desktop
					"precision mediump float;" +
					#end
					"varying vec2 vTexCoord;
					uniform sampler2D uImage0;
					
					void main(void)
					{
						gl_FragColor = texture2D (uImage0, vTexCoord);
					}";
				
				var fragmentShader = gl.createShader (gl.FRAGMENT_SHADER);
				gl.shaderSource (fragmentShader, fragmentShaderSource);
				gl.compileShader (fragmentShader);
				
				if (gl.getShaderParameter (fragmentShader, gl.COMPILE_STATUS) == 0) {
					
					throw "Error compiling fragment shader";
					
				}
				
				shaderProgram = gl.createProgram ();
				gl.attachShader (shaderProgram, vertexShader);
				gl.attachShader (shaderProgram, fragmentShader);
				gl.linkProgram (shaderProgram);
				
				if (gl.getProgramParameter (shaderProgram, gl.LINK_STATUS) == 0) {
					
					throw "Unable to initialize the shader program.";
					
				}
				
				// Create buffers
				
				var image = Assets.getImage ("assets/lime.png");
				
				var vertices = [
					
					image.width, image.height, 0,
					0, image.height, 0,
					image.width, 0, 0,
					0, 0, 0
					
				];
				
				vertexBuffer = gl.createBuffer ();
				gl.bindBuffer (gl.ARRAY_BUFFER, vertexBuffer);
				gl.bufferData (gl.ARRAY_BUFFER, new Float32Array (cast vertices), gl.STATIC_DRAW);
				gl.bindBuffer (gl.ARRAY_BUFFER, null);
				
				var texCoords = [
					
					1, 1, 
					0, 1, 
					1, 0, 
					0, 0, 
					
				];
				
				texCoordBuffer = gl.createBuffer ();
				gl.bindBuffer (gl.ARRAY_BUFFER, texCoordBuffer);	
				gl.bufferData (gl.ARRAY_BUFFER, new Float32Array (cast texCoords), gl.STATIC_DRAW);
				gl.bindBuffer (gl.ARRAY_BUFFER, null);
				
				// Create texture
				
				texture = gl.createTexture ();
				gl.bindTexture (gl.TEXTURE_2D, texture);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
				#if js
				gl.texImage2D (gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image.src);
				#else
				gl.texImage2D (gl.TEXTURE_2D, 0, gl.RGBA, image.textureWidth, image.textureHeight, 0, gl.RGBA, gl.UNSIGNED_BYTE, image.data);
				#end
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
				gl.bindTexture (gl.TEXTURE_2D, null);
			
			default:
			
		}
		
		initialized = true;
		
	}
	
	
	public override function render (context:RenderContext):Void {
		
		if (!initialized) {
			
			initialize (context);
			
		}
		
		switch (context) {
			
			case CANVAS (context):
				
				var image = Assets.getImage ("assets/lime.png");
				context.fillStyle = "#" + StringTools.hex (config.background, 6);
				context.fillRect (0, 0, window.width, window.height);
				context.drawImage (image.src, 0, 0, image.width, image.height);
				
			case DOM (element):
				
				// still visible
			
			case FLASH (sprite):
				
				var image = Assets.getImage ("assets/lime.png");
				sprite.graphics.beginBitmapFill (image.src);
				sprite.graphics.drawRect (0, 0, image.width, image.height);
			
			case OPENGL (gl):
				
				var r = ((config.background >> 16) & 0xFF) / 0xFF;
				var g = ((config.background >> 8) & 0xFF) / 0xFF;
				var b = (config.background & 0xFF) / 0xFF;
				var a = ((config.background >> 24) & 0xFF) / 0xFF;
				
				gl.clearColor (r, g, b, a);
				gl.clear (gl.COLOR_BUFFER_BIT);
				
				var vertexAttribute = gl.getAttribLocation (shaderProgram, "aPosition");
				var texCoordAttribute = gl.getAttribLocation (shaderProgram, "aTexCoord");
				var matrixUniform = gl.getUniformLocation (shaderProgram, "uMatrix");
				var imageUniform = gl.getUniformLocation (shaderProgram, "uImage0");
				
				var matrix = Matrix4.createOrtho (0, window.width, window.height, 0, -1000, 1000);
				
				gl.useProgram (shaderProgram);
				gl.enableVertexAttribArray (vertexAttribute);
				gl.enableVertexAttribArray (texCoordAttribute);
				
				gl.activeTexture (gl.TEXTURE0);
				gl.bindTexture (gl.TEXTURE_2D, texture);
				
				#if desktop
				gl.enable (gl.TEXTURE_2D);
				#end
				
				gl.bindBuffer (gl.ARRAY_BUFFER, vertexBuffer);
				gl.vertexAttribPointer (vertexAttribute, 3, gl.FLOAT, false, 0, 0);
				gl.bindBuffer (gl.ARRAY_BUFFER, texCoordBuffer);
				gl.vertexAttribPointer (texCoordAttribute, 2, gl.FLOAT, false, 0, 0);
				
				gl.uniformMatrix4fv (matrixUniform, false, matrix);
				gl.uniform1i (imageUniform, 0);
				
				gl.drawArrays (gl.TRIANGLE_STRIP, 0, 4);
				
				gl.bindBuffer (gl.ARRAY_BUFFER, null);
				gl.bindTexture (gl.TEXTURE_2D, null);
				
				#if desktop
				gl.disable (gl.TEXTURE_2D);
				#end
				
				gl.disableVertexAttribArray (vertexAttribute);
				gl.disableVertexAttribArray (texCoordAttribute);
				gl.useProgram (null);
				
			default:
			
		}
		
	}
	
	
}