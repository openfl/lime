
import lime.utils.Assets;
import lime.LiME;

    //Import GL stuff from nme
import lime.gl.GL;
import lime.gl.GLBuffer;
import lime.gl.GLProgram; 
import lime.gl.GLShader; 

    //utils
import lime.utils.Float32Array;
import lime.geometry.Matrix3D;


    //import the shader code for the examples
import shaders.FragmentShader_4278_1;
import shaders.FragmentShader_5359_8;
import shaders.FragmentShader_5398_8;
import shaders.FragmentShader_5454_21;
import shaders.FragmentShader_5492;
import shaders.FragmentShader_5733;
import shaders.FragmentShader_5805_18;
import shaders.FragmentShader_5812;
import shaders.FragmentShader_5891_5;
import shaders.FragmentShader_6022;
import shaders.FragmentShader_6043_1;
import shaders.FragmentShader_6049;
import shaders.FragmentShader_6147_1;
import shaders.FragmentShader_6162;
import shaders.FragmentShader_6175;
import shaders.FragmentShader_6223_2;
import shaders.FragmentShader_6238;
import shaders.FragmentShader_6284_1;
import shaders.FragmentShader_6286;
import shaders.FragmentShader_6288_1;
import shaders.VertexShader;

class Main {

	public var lib : LiME;

        //The list of shaders to cycle through

    public var slow_end_index : Int = 6;
    public var include_slow_expensive_examples : Bool = false;

#if !mobile
    
    private static var fragmentShaders:Array<Dynamic> = [ 
           //The top bunch are slow, expensive so for most users this is 
           //is a bad idea to just abuse their system when they run the sample
           //You can set the above value to true to see them though.
        FragmentShader_6223_2,
        FragmentShader_6175,
        FragmentShader_6162, 
        FragmentShader_6049, 
        FragmentShader_5359_8,
        FragmentShader_4278_1,

        FragmentShader_6286, 
        FragmentShader_6288_1, 
        FragmentShader_6284_1, 
        FragmentShader_6238, 
        FragmentShader_6147_1, 
        FragmentShader_6043_1, 
        FragmentShader_6022, 
        FragmentShader_5891_5, 
        FragmentShader_5805_18, 
        FragmentShader_5812, 
        FragmentShader_5733, 
        FragmentShader_5454_21, 
        FragmentShader_5492,  
        FragmentShader_5398_8 

    ];

#else //!mobile
    private static var fragmentShaders:Array<Dynamic> = [ FragmentShader_6284_1, FragmentShader_6238, FragmentShader_6147_1, FragmentShader_5891_5, FragmentShader_5805_18, FragmentShader_5492, FragmentShader_5398_8 ];
#end //if !mobile

        //The maximum time to spend on a shader example before cycling
    private static var maxTime = 2;

        //The current active shader example in the list
    private var currentIndex:Int;

        //The OpenGL values
    private var buffer:GLBuffer;
    private var currentProgram:GLProgram;
    private var positionAttribute:Dynamic;
    private var timeUniform:Dynamic;
    private var mouseUniform:Dynamic;
    private var resolutionUniform:Dynamic;
    private var backbufferUniform:Dynamic;
    private var surfaceSizeUniform:Dynamic;
    private var startTime:Dynamic;
    private var vertexPosition:Dynamic;

	public function new() {}

	public function ready( _lime : LiME ) {

        lib = _lime;
        
			// Init the shaders and view
		init();		

	}

        //called each frame by lime for logic (called before render)        
	public function update() {
		
        var time = haxe.Timer.stamp() - startTime;
        if (time > maxTime && fragmentShaders.length > 1) {
                
                //Pick a random example to show
            if( include_slow_expensive_examples ) {
                currentIndex = Std.random( fragmentShaders.length - 1 );
            } else {
                currentIndex = slow_end_index + Std.random( (fragmentShaders.length - slow_end_index - 1) );
            }

            compile ();
            
        }

	}

        //Called each frame by lime
	public function render() {
        
        GL.viewport( 0, 0, lib.config.width, lib.config.height );
        
        if (currentProgram == null) return;
        
        var time = haxe.Timer.stamp() - startTime;
        
        GL.useProgram (currentProgram);
        
        GL.uniform1f (timeUniform, time );
        //GL.uniform2f (mouseUniform, (Lib.current.stage.mouseX / Lib.current.stage.stageWidth) * 2 - 1, (Lib.current.stage.mouseY / Lib.current.stage.stageHeight) * 2 - 1);
        GL.uniform2f (mouseUniform, 0.1, 0.1);
        GL.uniform2f (resolutionUniform, lib.config.width, lib.config.height);
        GL.uniform1i (backbufferUniform, 0 );
        GL.uniform2f (surfaceSizeUniform, lib.config.width, lib.config.height);
        
        GL.bindBuffer (GL.ARRAY_BUFFER, buffer);
        GL.vertexAttribPointer (positionAttribute, 2, GL.FLOAT, false, 0, 0);
        GL.vertexAttribPointer (vertexPosition, 2, GL.FLOAT, false, 0, 0);
        
        GL.clearColor (0, 0, 0, 1);
        GL.clear (GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT );
        GL.drawArrays (GL.TRIANGLES, 0, 6);
        
        
 	
	}


	public function init() {

        currentIndex = (include_slow_expensive_examples ? 0 : slow_end_index);
            
        buffer = GL.createBuffer ();
        GL.bindBuffer (GL.ARRAY_BUFFER, buffer);
        GL.bufferData (GL.ARRAY_BUFFER, new Float32Array ([ -1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0 ]), GL.STATIC_DRAW);
            
        compile ();

    }

    private function compile ():Void {
        
        var program = GL.createProgram ();
        var vertex = VertexShader.source;
        
        #if desktop
        var fragment = "";
        #else
        var fragment = "precision mediump float;";
        #end
        
        fragment += fragmentShaders[currentIndex].source;
        
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
        GL.useProgram (currentProgram);
        
        positionAttribute = GL.getAttribLocation (currentProgram, "surfacePosAttrib");
        GL.enableVertexAttribArray (positionAttribute);
        
        vertexPosition = GL.getAttribLocation (currentProgram, "position");
        GL.enableVertexAttribArray (vertexPosition);
        
        timeUniform = GL.getUniformLocation (program, "time");
        mouseUniform = GL.getUniformLocation (program, "mouse");
        resolutionUniform = GL.getUniformLocation (program, "resolution");
        backbufferUniform = GL.getUniformLocation (program, "backbuffer");
        surfaceSizeUniform = GL.getUniformLocation (program, "surfaceSize");
        
        startTime = haxe.Timer.stamp();
        
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
    
    

}


