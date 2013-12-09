
    //Ported and modified from OpenFL samples
    //underscorediscovery

import lime.utils.Assets;
import lime.Lime;

    //Import GL stuff from lime
import lime.gl.GL;
import lime.gl.GLBuffer;
import lime.gl.GLProgram; 

    //utils
import lime.utils.Float32Array;
import lime.geometry.Matrix3D;


class Main {

	public var lib : Lime;

		//Shader stuff for drawing
    private var shaderProgram:GLProgram;
    private var vertexAttribute:Int;

    	//The vertices are stored in here for GL
    private var vertexBuffer:GLBuffer;	

    	//Some value to mess with the clear color
    private var red_value : Float = 1.0;
    private var red_direction : Int = 1;

    var end_dt : Float = 0.016;
    var dt : Float = 0.016;

	public function new() { }

	public function ready( _lime : Lime ) {

            //Store a reference
        lib = _lime;

			// Init the shaders and view
		init();
        
	} //ready


    public function init() {

            //Set up shaders
        createProgram();
        
            //Create a set of vertices
        var vertices : Float32Array = new Float32Array([
            100.0,    100.0,    0.0,
            -100.0,   100.0,    0.0,
            100.0,    -100.0,   0.0,
            -100.0,   -100.0,   0.0
        ]);
            
            //Create a buffer from OpenGL
        vertexBuffer = GL.createBuffer();
            //Bind it
        GL.bindBuffer( GL.ARRAY_BUFFER, vertexBuffer );  
            //Point it to the vertex array!
        GL.bufferData( GL.ARRAY_BUFFER, vertices, GL.STATIC_DRAW );

    } //init

        //Called each frame by lime for logic (called before render)
	public function update() {

        dt = haxe.Timer.stamp() - end_dt;
        end_dt = haxe.Timer.stamp();

			//an awful magic number to change the value slowly
		red_value += (red_direction * 0.3) * dt;

		if(red_value >= 1) {
			red_value = 1;
			red_direction = -red_direction;
		} else if(red_value <= 0) {
			red_value = 0;
			red_direction = -red_direction;
		}

	} //update

        //Called by lime 
    public function onmousemove(_event:Dynamic) {
    }
        //Called by lime 
    public function onmousedown(_event:Dynamic) {
    }
        //Called by lime 
    public function onmouseup(_event:Dynamic) {
    }
        //Called by lime 
    public function onkeydown(_event:Dynamic) {
    }    
        //Called by lime 
    public function onkeyup(_event:Dynamic) {
    }


        //Called by lime
	public function render() {

 			//Set the viewport for GL
 		GL.viewport( 0, 0, lib.config.width, lib.config.height );

            //Set the clear color to a weird color that bounces around
        GL.clearColor( red_value, red_value*0.5, red_value*0.3, 1);
        	//Clear the buffers
        GL.clear( GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT  );
                
            //Work out the middle of the viewport
        var positionX = (lib.config.width / 2) * (red_value*2);
        var positionY = (lib.config.height / 2) * (red_value*2);
        
        	//Create the projection and modelview matrices
        var projectionMatrix = Matrix3D.createOrtho (0, lib.config.width, lib.config.height, 0, 1000, -1000);
        var modelViewMatrix = Matrix3D.create2D (positionX, positionY, 1, 0);
        
        	//Bind the shader pointers to the vertex GL Buffer we made in init
        GL.bindBuffer (GL.ARRAY_BUFFER, vertexBuffer);
        GL.vertexAttribPointer (vertexAttribute, 3, GL.FLOAT, false, 0, 0);
        
        	//Set the projection values in the shader so they can render accordingly
        var projectionMatrixUniform = GL.getUniformLocation (shaderProgram, "projectionMatrix");
        var modelViewMatrixUniform = GL.getUniformLocation (shaderProgram, "modelViewMatrix");
        
        	//Update the GL Matrices
        GL.uniformMatrix3D (projectionMatrixUniform, false, projectionMatrix);
        GL.uniformMatrix3D (modelViewMatrixUniform, false, modelViewMatrix);
        
        	//And finally, Draw the vertices with the applied shaders and view
        GL.drawArrays (GL.TRIANGLE_STRIP, 0, 4);

	} //render


		//Shader initialize
	private function createProgram() : Void {
        
        var vertexShaderSource = 
            
            "attribute vec3 vertexPosition;
            
                uniform mat4 modelViewMatrix;
                uniform mat4 projectionMatrix;
            
            void main(void) {
                gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
            }";

        var fragmentShaderSource = 
            "void main(void) {
                gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
            }";

            //Create the GPU shaders
        var vertexShader = GL.createShader( GL.VERTEX_SHADER );
        var fragmentShader = GL.createShader( GL.FRAGMENT_SHADER );
            
                //Set the shader source and compile it
        GL.shaderSource( vertexShader, vertexShaderSource );
        GL.shaderSource( fragmentShader, fragmentShaderSource );
            
            //Try compiling the vertex shader    
        GL.compileShader( vertexShader );
        if (GL.getShaderParameter (vertexShader, GL.COMPILE_STATUS) == 0) {
            throw "Error compiling vertex shader";
        } //COMPILE_STATUS
        
            //Now try compile the fragment shader            
        GL.compileShader( fragmentShader );
        if (GL.getShaderParameter(fragmentShader, GL.COMPILE_STATUS) == 0) {
            throw "Error compiling fragment shader";
        } //COMPILE_STATUS
            
            //Create the GPU program
        shaderProgram = GL.createProgram();

                //Attach the shader code to the program
            GL.attachShader( shaderProgram, vertexShader );
            GL.attachShader( shaderProgram, fragmentShader );

            //And link the program
        GL.linkProgram( shaderProgram );
        if (GL.getProgramParameter (shaderProgram, GL.LINK_STATUS) == 0) {
            throw "Unable to initialize the shader program.";
        } //LINK_STATUS
            
            //Set the shader active
        GL.useProgram( shaderProgram );
            //Fetch the vertex attribute
        vertexAttribute = GL.getAttribLocation (shaderProgram, "vertexPosition");
            //And enable it (disable by default)
        GL.enableVertexAttribArray (vertexAttribute);
        
    } //createProgram


} //Main


