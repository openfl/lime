package;


import haxe.Timer;
import lime.gl.GL;
import lime.gl.GLBuffer;
import lime.gl.GLProgram;
import lime.gl.GLShader;
import lime.gl.GLUniformLocation;
import lime.geometry.Matrix3D;
import lime.utils.Float32Array;
import lime.utils.Assets;
import lime.Lime;


class Main {
	
	
	private static var fragmentShaders = [ #if mobile "6284.1", "6238", "6147.1", "5891.5", "5805.18", "5492", "5398.8" #else "6286", "6288.1", "6284.1", "6238", "6223.2", "6175", "6162", "6147.1", "6049", "6043.1", "6022", "5891.5", "5805.18", "5812", "5733", "5454.21", "5492", "5359.8", "5398.8", "4278.1" #end ];
	private static var maxTime = 7;
	
	private var backbufferUniform:GLUniformLocation;
	private var buffer:GLBuffer;
	private var currentIndex:Int;
	private var currentProgram:GLProgram;
	private var currentTime:Float;
	private var lime:Lime;
	private var mouseUniform:GLUniformLocation;
	private var positionAttribute:Int;
	private var resolutionUniform:GLUniformLocation;
	private var startTime:Float;
	private var surfaceSizeUniform:GLUniformLocation;
	private var timeUniform:GLUniformLocation;
	private var vertexPosition:Int;
	
	
	public function new () {}
	
	
	private function compile ():Void {
		
		var program = GL.createProgram ();
		var vertex = Assets.getText ("assets/heroku.vert");
		
		#if desktop
		var fragment = "";
		#else
		var fragment = "precision mediump float;";
		#end
		
		fragment += Assets.getText ("assets/" + fragmentShaders[currentIndex] + ".frag");
		
		var vs = createShader (vertex, GL.VERTEX_SHADER);
		var fs = createShader (fragment, GL.FRAGMENT_SHADER);
		
		if (vs == null || fs == null) return;
		
		GL.attachShader (program, vs);
		GL.attachShader (program, fs);
		
		GL.deleteShader (vs);
		GL.deleteShader (fs);
		
		GL.linkProgram (program);
		
		if (GL.getProgramParameter (program, GL.LINK_STATUS) == 0) {
			
			trace (GL.getProgramInfoLog (program));
			trace ("VALIDATE_STATUS: " + GL.getProgramParameter (program, GL.VALIDATE_STATUS));
			trace ("ERROR: " + GL.getError ());
			return;
			
		}
		
		if (currentProgram != null) {
			
			GL.deleteProgram (currentProgram);
			
		}
		
		currentProgram = program;
		
		positionAttribute = GL.getAttribLocation (currentProgram, "surfacePosAttrib");
		GL.enableVertexAttribArray (positionAttribute);
		
		vertexPosition = GL.getAttribLocation (currentProgram, "position");
		GL.enableVertexAttribArray (vertexPosition);
		
		timeUniform = GL.getUniformLocation (program, "time");
		mouseUniform = GL.getUniformLocation (program, "mouse");
		resolutionUniform = GL.getUniformLocation (program, "resolution");
		backbufferUniform = GL.getUniformLocation (program, "backbuffer");
		surfaceSizeUniform = GL.getUniformLocation (program, "surfaceSize");
		
		startTime = Timer.stamp ();
		currentTime = startTime;
		
	}
	
	
	private function createShader (source:String, type:Int):GLShader {
		
		var shader = GL.createShader (type);
		GL.shaderSource (shader, source);
		GL.compileShader (shader);
		
		if (GL.getShaderParameter (shader, GL.COMPILE_STATUS) == 0) {
			
			trace (GL.getShaderInfoLog (shader));
			return null;
			
		}
		
		return shader;
		
	}
	
	
	private function randomizeArray<T> (array:Array<T>):Array<T> {
		
		var arrayCopy = array.copy ();
		var randomArray = new Array<T> ();
		
		while (arrayCopy.length > 0) {
			
			var randomIndex = Math.round (Math.random () * (arrayCopy.length - 1));
			randomArray.push (arrayCopy.splice (randomIndex, 1)[0]);
			
		}
		
		return randomArray;
		
	}
	
	
	public function ready (lime:Lime) {
		
		this.lime = lime;
		
		fragmentShaders = randomizeArray (fragmentShaders);
		currentIndex = 0;
		
		buffer = GL.createBuffer ();
		GL.bindBuffer (GL.ARRAY_BUFFER, buffer);
		GL.bufferData (GL.ARRAY_BUFFER, new Float32Array ([ -1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0 ]), GL.STATIC_DRAW);
		GL.bindBuffer (GL.ARRAY_BUFFER, null);
		
		compile ();
		
	}
	
	
	public function render ():Void {
		
		if (currentProgram == null) return;
		
		currentTime = Timer.stamp () - startTime;
		
		GL.viewport (0, 0, lime.config.width, lime.config.height);
		GL.useProgram (currentProgram);
		
		GL.uniform1f (timeUniform, currentTime);
		GL.uniform2f (mouseUniform, 0.1, 0.1); //GL.uniform2f (mouseUniform, (stage.mouseX / stage.stageWidth) * 2 - 1, (stage.mouseY / stage.stageHeight) * 2 - 1);
		GL.uniform2f (resolutionUniform, lime.config.width, lime.config.height);
		GL.uniform1i (backbufferUniform, 0 );
		GL.uniform2f (surfaceSizeUniform, lime.config.width, lime.config.height);
		
		GL.bindBuffer (GL.ARRAY_BUFFER, buffer);
		GL.vertexAttribPointer (positionAttribute, 2, GL.FLOAT, false, 0, 0);
		GL.vertexAttribPointer (vertexPosition, 2, GL.FLOAT, false, 0, 0);
		
		GL.clearColor (0, 0, 0, 1);
		GL.clear (GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT );
		GL.drawArrays (GL.TRIANGLES, 0, 6);
		GL.bindBuffer (GL.ARRAY_BUFFER, null);
		
	}
	
	
	public function update ():Void {
		
		if (currentTime > maxTime && fragmentShaders.length > 1) {
			
			currentIndex++;
			
			if (currentIndex > fragmentShaders.length - 1) {
				
				currentIndex = 0;
				
			}
			
			compile ();
			
		}
		
	}
	
	
}