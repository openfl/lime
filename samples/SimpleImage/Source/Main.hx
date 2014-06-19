package;


import lime.app.Application;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.graphics.ImageData;
import lime.graphics.GLRenderContext;
import lime.graphics.RenderContext;
import lime.utils.Float32Array;
import lime.Assets;


#if html5
@:access(lime.graphics.opengl.GL)
#end
class Main extends Application {
	
	
	private var image:ImageData;
	private var initialized:Bool;
	
	private var shaderProgram:GLProgram;
	private var texCoordBuffer:GLBuffer;
	private var texture:GLTexture;
	private var vertexBuffer:GLBuffer;
	
	
	public function new () {
		
		super ();
		
		image = Assets.getImageData ("assets/lime.png");
		
	}
	
	
	private function initialize (context:RenderContext):Void {
		
		switch (context) {
			
			case DOM (element):
				
				var div = element.ownerDocument.createElement ("div");
				div.style.width = image.width + "px";
				div.style.height = image.height + "px";
				div.style.backgroundImage = "url('" + Assets.getPath ("assets/lime.png") + ")";
				element.appendChild (image.data);
			
			case OPENGL (gl):
				
				// Initialize shaders
				
				var vertexShaderSource = 
					
					"attribute vec3 aVertexPosition;
					attribute vec2 aTexCoord;
					varying vec2 vTexCoord;
					
					uniform mat4 uModelViewMatrix;
					uniform mat4 uProjectionMatrix;
					
					void main(void) {
						vTexCoord = aTexCoord;
						gl_Position = uProjectionMatrix * uModelViewMatrix * vec4 (aVertexPosition, 1.0);
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
				#if html5
				gl.texImage2D (gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image.data);
				#else
				gl.texImage2D (gl.TEXTURE_2D, 0, gl.RGBA, image.width, image.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, image.data);
				#end
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
				gl.texParameteri (gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
				gl.bindTexture (gl.TEXTURE_2D, null);
			
			default:
			
		}
		
	}
	
	
	public override function render (context:RenderContext):Void {
		
		if (!initialized) {
			
			initialize (context);
			initialized = true;
			
		}
		
		switch (context) {
			
			case CANVAS (context):
				
				context.drawImage (image.data, 0, 0, image.width, image.height);
				
			case DOM (element):
				
				// still visible
			
			case FLASH (sprite):
				
				sprite.graphics.beginBitmapFill (image.data);
				sprite.graphics.drawRect (0, 0, image.width, image.height);
			
			case OPENGL (gl):
				
				gl.clearColor (1.0, 1.0, 1.0, 1.0);
				gl.clear (gl.COLOR_BUFFER_BIT);
				
				var vertexAttribute = gl.getAttribLocation (shaderProgram, "aVertexPosition");
				var texCoordAttribute = gl.getAttribLocation (shaderProgram, "aTexCoord");
				var projectionMatrixUniform = gl.getUniformLocation (shaderProgram, "uProjectionMatrix");
				var modelViewMatrixUniform = gl.getUniformLocation (shaderProgram, "uModelViewMatrix");
				var imageUniform = gl.getUniformLocation (shaderProgram, "uImage0");
				
				var positionX = 0;
				var positionY = 0;
				var width = config.width;
				var height = config.height;
				
				var projectionMatrix = new Float32Array ([ 2 / width, 0, 0, 0, 0, 2 / height, 0, 0, 0, 0, -0.0001, 0, -1, -1, 1, 1 ]);
				
				var rotation = 0;
				var scale = 1;
				var theta = rotation * Math.PI / 180;
				var c = Math.cos (theta);
				var s = Math.sin (theta);
				
				var modelViewMatrix = new Float32Array ([ c * scale, -s * scale, 0, 0, s * scale, c * scale, 0, 0, 0, 0, 1, 0, positionX, positionY, 0, 1 ]);
				
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
				
				gl.uniformMatrix4fv (projectionMatrixUniform, false, projectionMatrix);
				gl.uniformMatrix4fv (modelViewMatrixUniform, false, modelViewMatrix);
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