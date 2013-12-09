
    //Ported and modified from OpenFL examples
    //underscorediscovery

import lime.utils.Assets;
import lime.Lime;

    //Import GL stuff from Lime
import lime.gl.GL;
import lime.gl.GLBuffer;
import lime.gl.GLProgram; 
import lime.gl.GLShader; 

    //utils
import lime.utils.Float32Array;
import lime.geometry.Matrix3D;
import lime.InputHandler.MouseEvent;

    //import the shader code for the examples
    //todo : Port to assets like latest openfl example
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

	public var lib : Lime;
    

           //A bunch of these shaders are expensive so for most users this is 
           //is a bad idea to just abuse their system when they run the sample.
           //You can set the below value to true to see them though.    
    public var include_slow_expensive_examples : Bool = false;
    public var slow_end_index : Int = 6;

    private var mouse_x : Int = 0;
    private var mouse_y : Int = 0;

        //The maximum time to spend on a shader example before cycling
        //We start really quickly, 
            //a) because we want to make sure the user knows there are more than 1 and 
            //b) because the first index is fixed, but the randomness can pick a new one
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

        //Ready is called by lime when it has created the window etc.
        //We can start using GL here.
	public function ready( _lime : Lime ) {

            //Store a reference, in case we want it
        lib = _lime;
        
			// Init the shaders and view
		init();		

	} //ready

    public function init() {

            //Find the starting index
        currentIndex = (include_slow_expensive_examples ? 0 : slow_end_index);
            
            //Create a vertex buffer, for a Quad, bind it and submit it once using STATIC draw so it stays in GPU
        buffer = GL.createBuffer();
        GL.bindBuffer(GL.ARRAY_BUFFER, buffer);
        GL.bufferData(GL.ARRAY_BUFFER, new Float32Array ([ -1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0 ]), GL.STATIC_DRAW);
            
            //start the mouse center screen
            //lime stores the window size in it's config (as well as other window options)
        mouse_x = Std.int(lib.config.width/2);
        mouse_y = Std.int(lib.config.height/2);

            //Compile the shader selected
        compile();

    } //init

        //lime will call this when the mouse moves, so we can get a position
    public function onmousemove( e:MouseEvent ) {

        mouse_x = Std.int(e.x);
        mouse_y = Std.int(e.y);

    } //onmousemove

        //we also set this on mouse down, so mobile has some interactivity (could also use ontouchdown)
    public function onmousedown( e:MouseEvent ) {

        mouse_x = Std.int(e.x); 
        mouse_y = Std.int(e.y);

    } //onmousedown

        //called each frame by lime for logic (called before render)        
	public function update() {
		  
          //check if we have passed the max time for watching this shader
        var time = haxe.Timer.stamp() - startTime;
        if (time > maxTime && fragmentShaders.length > 1) {
                
                //Pick a random example to show

            #if !mobile                    
                if( include_slow_expensive_examples ) {
                    currentIndex = Std.random( fragmentShaders.length - 1 );
                } else {    
                    currentIndex = slow_end_index + Std.random( (fragmentShaders.length - slow_end_index - 1) );
                }
            #else 
                currentIndex = Std.random( fragmentShaders.length - 1 );
            #end

                //recompile using this index
            compile();

                //switch time if after the first one
            if(maxTime == 2) maxTime = 10;
            
        } //if time is passed max time

	} //update


        //Called each frame by lime, when the window wants to render
	public function render() {
            
            //Set the viewport to the config window size
        GL.viewport( 0, 0, lib.config.width, lib.config.height );
            
            //If the shader failed to link or compile we don't render yet
        if (currentProgram == null) return;
            
            //The current time is the time since the last shader started, and now
        var time = haxe.Timer.stamp() - startTime;
            
            //Activate the current shader
        GL.useProgram(currentProgram);
            
            //Pass the attributes to the shaders
        GL.uniform1f( timeUniform, time );
        GL.uniform2f( mouseUniform, (mouse_x / lib.config.width) * 2 - 1, (mouse_y / lib.config.height) * 2 - 1 );
        GL.uniform2f( resolutionUniform, lib.config.width, lib.config.height );
        GL.uniform1i( backbufferUniform, 0 );
        GL.uniform2f( surfaceSizeUniform, lib.config.width, lib.config.height );
            
            //Point to the buffer we created earlier to draw
        GL.bindBuffer( GL.ARRAY_BUFFER, buffer );
        GL.vertexAttribPointer( positionAttribute, 2, GL.FLOAT, false, 0, 0 );
        GL.vertexAttribPointer( vertexPosition, 2, GL.FLOAT, false, 0, 0 );
            
            //Clear the screen
        GL.clearColor(0, 0, 0, 1);
        GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT );

            //And finally draw the quad!
        GL.drawArrays (GL.TRIANGLES, 0, 6);
        
	} //render

    private function compile ():Void {
        
        var program = GL.createProgram ();
        var vertex = VertexShader.source;
            
            //When on web specifically we prefix the shader with a required precision qualifier
        #if desktop
            var fragment = "";
        #else
            var fragment = "precision mediump float;";
        #end
            
        fragment += fragmentShaders[currentIndex].source;
        
        var vs = createShader(vertex,   GL.VERTEX_SHADER);
        var fs = createShader(fragment, GL.FRAGMENT_SHADER);
            
            //Woops, this didn't compile so jump out
            //todo : Add compiler logs.
        if (vs == null || fs == null) {
            return;
        }
            
            //Attach the shaders to the program
        GL.attachShader(program, vs);
        GL.attachShader(program, fs);
            //Clean up unnecessary shader references (they are stored by index in the Program)
        GL.deleteShader(vs);
        GL.deleteShader(fs);

            //Link the program on the GPU
        GL.linkProgram (program);
            
            //Check if linking was good
        if (GL.getProgramParameter (program, GL.LINK_STATUS) == 0) {
            
            trace( GL.getProgramInfoLog(program) );
            trace( "VALIDATE_STATUS: " + GL.getProgramParameter (program, GL.VALIDATE_STATUS));
            trace( "ERROR: " + GL.getError() );
            return;

        } //GL.LINK_STATUS == 0
            
            //If we had an existing program? Clean up
        if (currentProgram != null) {
            GL.deleteProgram (currentProgram);
        }
            
            //Store the new program
        currentProgram = program;
            //Activate the new program
        GL.useProgram(currentProgram);
            
            //Make sure that the attributes are referenced correctly 
        positionAttribute = GL.getAttribLocation(currentProgram, "surfacePosAttrib");        
        vertexPosition = GL.getAttribLocation (currentProgram, "position");
            //As well as enabled
        GL.enableVertexAttribArray (vertexPosition);
        GL.enableVertexAttribArray(positionAttribute);
            
            //And for the uniforms, we store their location because it can change per shader
        timeUniform = GL.getUniformLocation(program, "time");
        mouseUniform = GL.getUniformLocation(program, "mouse");
        resolutionUniform = GL.getUniformLocation(program, "resolution");
        backbufferUniform = GL.getUniformLocation(program, "backbuffer");
        surfaceSizeUniform = GL.getUniformLocation(program, "surfaceSize");
        
            //So that we can calculate the new shader running time
        startTime = haxe.Timer.stamp();
        
    } //compile

        //Take a source shader, compile it, check for errors and return the GLShader
    private function createShader( source:String, type:Int ) : GLShader {
        
        var shader = GL.createShader (type);

            GL.shaderSource(shader, source);
            GL.compileShader(shader);
        
        if (GL.getShaderParameter(shader, GL.COMPILE_STATUS) == 0) {
            return null;
        }
        
        return shader;
        
    } //createShader
    

#if !mobile
        
        //The list of shaders to cycle through    
    private static var fragmentShaders:Array<Dynamic> = [ 
            //These are the more expensive ones, excluded by default
        FragmentShader_6223_2,
        FragmentShader_6175,
        FragmentShader_6162, 
        FragmentShader_6049, 
        FragmentShader_5359_8,
        FragmentShader_4278_1,
            //These are the ok ones
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

        //These are mobile ones
    private static var fragmentShaders:Array<Dynamic> = [ 
        FragmentShader_6284_1, 
        FragmentShader_6238, 
        FragmentShader_6147_1, 
        FragmentShader_5891_5, 
        FragmentShader_5805_18, 
        FragmentShader_5492, 
        FragmentShader_5398_8 
    ];
    
#end //if !mobile


} //Main class


