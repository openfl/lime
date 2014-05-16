package;


import format.png.Reader;
import format.png.Tools;
import haxe.io.Bytes;
import haxe.io.BytesData;
import haxe.io.BytesInput;
import lime.gl.GL;
import lime.gl.GLBuffer;
import lime.gl.GLProgram;
import lime.gl.GLTexture;
import lime.gl.GLUniformLocation;
import lime.utils.ByteArray;
import lime.utils.Matrix3D;
import lime.utils.Assets;
import lime.utils.Float32Array;
import lime.utils.UInt8Array;
import lime.Lime;


class Main {
	
	
	private var imageData:UInt8Array;
	private var imageHeight:Int;
	private var imageWidth:Int;
	private var imageUniform:GLUniformLocation;
	private var lime:Lime;
	private var modelViewMatrixUniform:GLUniformLocation;
	private var projectionMatrixUniform:GLUniformLocation;
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
		
		var vertexShaderSource = "";
			
		#if lime_html5
			vertexShaderSource += "precision mediump float;";
		#end 

		vertexShaderSource += "attribute vec3 aVertexPosition;
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
		
		var fragmentShaderSource = "";

		#if lime_html5
			fragmentShaderSource += "precision mediump float;";
		#end 
			
		fragmentShaderSource += 
			"varying vec2 vTexCoord;
			uniform sampler2D uImage0;
			
			void main(void)
			{
				gl_FragColor = texture2D (uImage0, vTexCoord);
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
	

#if lime_html5

    function load_image(_id:String, onload:Void->Void) {

    	var image: js.html.ImageElement = js.Browser.document.createImageElement();
        
        image.onload = function(a) {

            try {

                var tmp_canvas = js.Browser.document.createCanvasElement();
                	tmp_canvas.width = image.width; 
                	tmp_canvas.height = image.height;

                var tmp_context = tmp_canvas.getContext2d();
                	tmp_context.clearRect( 0,0, tmp_canvas.width, tmp_canvas.height );
                	tmp_context.drawImage( image, 0, 0, image.width, image.height );

                var image_bytes = tmp_context.getImageData( 0, 0, tmp_canvas.width, tmp_canvas.height );
                var haxe_bytes = new lime.utils.UInt8Array( image_bytes.data );

                imageData = haxe_bytes;
                imageHeight = image.width;
                imageWidth = image.height;

                tmp_canvas = null;
                tmp_context = null;
                haxe_bytes = null;
                image_bytes = null;

                onload();

            } catch(e:Dynamic) {

            	trace(e);
                var tips = '- textures might require power of two sizes\n';
                	tips += '- textures served from file:/// throw security errors\n';
                    tips += '- textures served over http:// work for cross origin';

                trace(tips);
                throw e;

            }

        } //image.onload

            //source comes after the onload being set, for race conditions
        image.src = _id;

    } //load_html5_image

#else

	function load_image(_id:String, onload:Void->Void) {

		var bytes : ByteArray = Assets.getBytes (_id);
		var byteInput = new BytesInput ( bytes, 0, bytes.length);
		var png = new Reader (byteInput).read ();
		var data = Tools.extract32 (png);
		var header = Tools.getHeader (png);
		
		imageWidth = header.width;
		imageHeight = header.height;
		imageData = new UInt8Array (data.getData ());

		var image_length = imageWidth * imageHeight;

			//bytes are returned in a different order, bgra
			//so we swap back to rgba 
        for(i in 0 ... image_length) {

            var b = imageData[i*4+0];
            var g = imageData[i*4+1];
            var r = imageData[i*4+2];
            var a = imageData[i*4+3];

            imageData[i*4+0] = r;
            imageData[i*4+1] = g;
            imageData[i*4+2] = b;
            imageData[i*4+3] = a;

        }

		onload();
		
	}

#end  //!lime_html5
	
	var loaded = false;

	public function ready (lime:Lime):Void {
		
		this.lime = lime;
		
			//we load the image with a callback,
			//because on html5 it is asynchronous and we want
			//to only try and use it when it's done loading
		load_image("assets/lime.png", function(){

			initializeShaders ();
			
			createBuffers ();
			createTexture ();

			loaded = true;

		});
		
	}
	
	
	private function render ():Void {
		
		if(!loaded) {
			return;
		}

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
		
		GL.bindBuffer (GL.ARRAY_BUFFER, vertexBuffer);
		GL.vertexAttribPointer (vertexAttribute, 3, GL.FLOAT, false, 0, 0);
		GL.bindBuffer (GL.ARRAY_BUFFER, texCoordBuffer);
		GL.vertexAttribPointer (texCoordAttribute, 2, GL.FLOAT, false, 0, 0);
		
		GL.uniformMatrix3D (projectionMatrixUniform, false, projectionMatrix);
		GL.uniformMatrix3D (modelViewMatrixUniform, false, modelViewMatrix);
		GL.uniform1i (imageUniform, 0);
		
		GL.drawArrays (GL.TRIANGLE_STRIP, 0, 4);
		
		GL.bindBuffer (GL.ARRAY_BUFFER, null);
		GL.bindTexture (GL.TEXTURE_2D, null);
		
		GL.disableVertexAttribArray (vertexAttribute);
		GL.disableVertexAttribArray (texCoordAttribute);
		GL.useProgram (null);
		
	}
	
	
}
