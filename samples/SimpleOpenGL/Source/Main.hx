package;


import format.png.Reader;
import format.png.Tools;
import haxe.io.BytesInput;
import lime.gl.GL;
import lime.gl.GLBuffer;
import lime.gl.GLProgram;
import lime.gl.GLTexture;
import lime.geometry.Matrix3D;
import lime.utils.Assets;
import lime.utils.Float32Array;
import lime.utils.UInt8Array;
import lime.Lime;


class Main {
	
	
	private var imageData:UInt8Array;
	private var imageHeight:Int;
	private var imageWidth:Int;
	private var imageUniform:Int;
	private var lime:Lime;
	private var modelViewMatrixUniform:Int;
	private var projectionMatrixUniform:Int;
	private var shaderProgram:GLProgram;
	private var texCoordAttribute:Int;
	private var texCoordBuffer:GLBuffer;
	private var texture:GLTexture;
	private var vertexAttribute:Int;
	private var vertexBuffer:GLBuffer;
	
	
	public function new () {}
	
	
	private function createBuffers ():Void {
		
		var vertices = [
			
			imageWidth, imageHeight, 0,
			0, imageHeight, 0,
			imageWidth, 0, 0,
			0, 0, 0
			
		];
		
		vertexBuffer = GL.createBuffer ();
		GL.bindBuffer (GL.ARRAY_BUFFER, vertexBuffer);
		GL.bufferData (GL.ARRAY_BUFFER, new Float32Array (cast vertices), GL.STATIC_DRAW);
		GL.bindBuffer (GL.ARRAY_BUFFER, null);
		
		var texCoords = [
			
			1, 1, 
			0, 1, 
			1, 0, 
			0, 0, 
			
		];
		
		texCoordBuffer = GL.createBuffer ();
		GL.bindBuffer (GL.ARRAY_BUFFER, texCoordBuffer);	
		GL.bufferData (GL.ARRAY_BUFFER, new Float32Array (cast texCoords), GL.STATIC_DRAW);
		GL.bindBuffer (GL.ARRAY_BUFFER, null);
		
	}
	
	
	private function createTexture ():Void {
		
		texture = GL.createTexture ();
		GL.bindTexture (GL.TEXTURE_2D, texture);
		GL.texImage2D (GL.TEXTURE_2D, 0, GL.RGBA, imageHeight, imageHeight, 0, GL.RGBA, GL.UNSIGNED_BYTE, imageData);
		GL.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
		GL.texParameteri (GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
		GL.bindTexture (GL.TEXTURE_2D, null);
		
	}
	
	
	private function initializeShaders ():Void {
		
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
		
		var vertexShader = GL.createShader (GL.VERTEX_SHADER);
		GL.shaderSource (vertexShader, vertexShaderSource);
		GL.compileShader (vertexShader);
		
		if (GL.getShaderParameter (vertexShader, GL.COMPILE_STATUS) == 0) {
			
			throw "Error compiling vertex shader";
			
		}
		
		var fragmentShaderSource = 
			
			"varying vec2 vTexCoord;
			uniform sampler2D uImage0;
			
			void main(void)
			{
				gl_FragColor = texture2D (uImage0, vTexCoord).bgra;
			}";
		
		var fragmentShader = GL.createShader (GL.FRAGMENT_SHADER);
		GL.shaderSource (fragmentShader, fragmentShaderSource);
		GL.compileShader (fragmentShader);
		
		if (GL.getShaderParameter (fragmentShader, GL.COMPILE_STATUS) == 0) {
			
			throw "Error compiling fragment shader";
			
		}
		
		shaderProgram = GL.createProgram ();
		GL.attachShader (shaderProgram, vertexShader);
		GL.attachShader (shaderProgram, fragmentShader);
		GL.linkProgram (shaderProgram);
		
		if (GL.getProgramParameter (shaderProgram, GL.LINK_STATUS) == 0) {
			
			throw "Unable to initialize the shader program.";
			
		}
		
		vertexAttribute = GL.getAttribLocation (shaderProgram, "aVertexPosition");
		texCoordAttribute = GL.getAttribLocation (shaderProgram, "aTexCoord");
		projectionMatrixUniform = GL.getUniformLocation (shaderProgram, "uProjectionMatrix");
		modelViewMatrixUniform = GL.getUniformLocation (shaderProgram, "uModelViewMatrix");
		imageUniform = GL.getUniformLocation (shaderProgram, "uImage0");
		
	}
	
	
	public function ready (lime:Lime):Void {
		
		this.lime = lime;
		
		var bytes = Assets.getBytes ("assets/lime.png");
		var byteInput = new BytesInput (bytes, 0, bytes.length);
		var png = new Reader (byteInput).read ();
		var data = Tools.extract32 (png);
		var header = Tools.getHeader (png);
		
		imageWidth = header.width;
		imageHeight = header.height;
		imageData = new UInt8Array (data.getData ());
		
		initializeShaders ();
		
		createBuffers ();
		createTexture ();
		
	}
	
	
	private function render ():Void {
		
		GL.viewport (0, 0, lime.config.width, lime.config.height);
		
		GL.clearColor (1.0, 1.0, 1.0, 1.0);
		GL.clear (GL.COLOR_BUFFER_BIT);
		
		var positionX = (lime.config.width - imageWidth) / 2;
		var positionY = (lime.config.height - imageHeight) / 2;
		
		var projectionMatrix = Matrix3D.createOrtho (0, lime.config.width, lime.config.height, 0, 1000, -1000);
		var modelViewMatrix = Matrix3D.create2D (positionX, positionY, 1, 0);
		
		GL.useProgram (shaderProgram);
		GL.enableVertexAttribArray (vertexAttribute);
		GL.enableVertexAttribArray (texCoordAttribute);
		
		GL.activeTexture (GL.TEXTURE0);
		GL.bindTexture (GL.TEXTURE_2D, texture);
		GL.enable (GL.TEXTURE_2D);
		
		GL.bindBuffer (GL.ARRAY_BUFFER, vertexBuffer);
		GL.vertexAttribPointer (vertexAttribute, 3, GL.FLOAT, false, 0, 0);
		GL.bindBuffer (GL.ARRAY_BUFFER, texCoordBuffer);
		GL.vertexAttribPointer (texCoordAttribute, 2, GL.FLOAT, false, 0, 0);
		
		GL.uniformMatrix3D (projectionMatrixUniform, false, projectionMatrix);
		GL.uniformMatrix3D (modelViewMatrixUniform, false, modelViewMatrix);
		GL.uniform1i (imageUniform, 0);
		
		GL.drawArrays (GL.TRIANGLE_STRIP, 0, 4);
		
		GL.bindBuffer (GL.ARRAY_BUFFER, null);
		GL.disable (GL.TEXTURE_2D);
		GL.bindTexture (GL.TEXTURE_2D, null);
		
		GL.disableVertexAttribArray (vertexAttribute);
		GL.disableVertexAttribArray (texCoordAttribute);
		GL.useProgram (null);
		
	}
	
	
}