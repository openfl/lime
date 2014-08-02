package;


import haxe.Timer;
import lime.app.Application;
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLShader;
import lime.graphics.opengl.GLUniformLocation;
import lime.graphics.RenderContext;
import lime.utils.Float32Array;
import lime.Assets;


class Main extends Application {
	
	
	private static var fragmentShaders = [ #if mobile "6284.1", "6238", "6147.1", "5891.5", "5805.18", "5492", "5398.8" #else "6286", "6288.1", "6284.1", "6238", "6223.2", "6175", "6162", "6147.1", "6049", "6043.1", "6022", "5891.5", "5805.18", "5812", "5733", "5454.21", "5492", "5359.8", "5398.8", "4278.1" #end ];
	private static var maxTime = 7;
	
	private var backbufferUniform:GLUniformLocation;
	private var buffer:GLBuffer;
	private var currentIndex:Int;
	private var currentProgram:GLProgram;
	private var currentTime:Float;
	private var mouseUniform:GLUniformLocation;
	private var positionAttribute:Int;
	private var resolutionUniform:GLUniformLocation;
	private var startTime:Float;
	private var surfaceSizeUniform:GLUniformLocation;
	private var timeUniform:GLUniformLocation;
	private var vertexPosition:Int;
	
	
	public function new () {
		
		super ();
		
	}
	
	
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
	
	
	public override function init (context:RenderContext):Void {
		
		switch (context) {
			
			case OPENGL (gl):
				
				fragmentShaders = randomizeArray (fragmentShaders);
				currentIndex = 0;
				
				buffer = gl.createBuffer ();
				gl.bindBuffer (gl.ARRAY_BUFFER, buffer);
				gl.bufferData (gl.ARRAY_BUFFER, new Float32Array ([ -1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0 ]), gl.STATIC_DRAW);
				gl.bindBuffer (gl.ARRAY_BUFFER, null);
				
				compile ();
				
			default:
				
				// not implemented
			
		}
		
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
	
	
	public override function render (context:RenderContext):Void {
		
		switch (context) {
			
			case OPENGL (gl):
				
				if (currentProgram == null) return;
				
				currentTime = Timer.stamp () - startTime;
				
				gl.viewport (0, 0, window.width, window.height);
				gl.useProgram (currentProgram);
				
				gl.uniform1f (timeUniform, currentTime);
				gl.uniform2f (mouseUniform, 0.1, 0.1); //GL.uniform2f (mouseUniform, (stage.mouseX / stage.stageWidth) * 2 - 1, (stage.mouseY / stage.stageHeight) * 2 - 1);
				gl.uniform2f (resolutionUniform, window.width, window.height);
				gl.uniform1i (backbufferUniform, 0 );
				gl.uniform2f (surfaceSizeUniform, window.width, window.height);
				
				gl.bindBuffer (gl.ARRAY_BUFFER, buffer);
				gl.vertexAttribPointer (positionAttribute, 2, gl.FLOAT, false, 0, 0);
				gl.vertexAttribPointer (vertexPosition, 2, gl.FLOAT, false, 0, 0);
				
				gl.clearColor (0, 0, 0, 1);
				gl.clear (gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT );
				gl.drawArrays (gl.TRIANGLES, 0, 6);
				gl.bindBuffer (gl.ARRAY_BUFFER, null);
				
			default:
				
				// not implemented
			
		}
		
		
		
	}
	
	
	public override function update (deltaTime:Int):Void {
		
		if (currentTime > maxTime && fragmentShaders.length > 1) {
			
			currentIndex++;
			
			if (currentIndex > fragmentShaders.length - 1) {
				
				currentIndex = 0;
				
			}
			
			compile ();
			
		}
		
	}
	
	
}
