
import nmegl.utils.Assets;
import nmegl.NMEGL;

    //Import GL stuff from nme
import nmegl.gl.GL;
import nmegl.gl.GLBuffer;
import nmegl.gl.GLProgram; 

    //utils
import nmegl.utils.Float32Array;
import nmegl.geometry.Matrix3D;

class Main {

	public var lib : NMEGL;

		//Shader stuff for drawing
    private var shaderProgram:GLProgram;
    private var vertexAttribute:Int;

    	//The vertices are stored in here for GL
    private var vertexBuffer:GLBuffer;	

    	//Some value to mess with the clear color
    private var red_value : Float = 1.0;
    private var red_direction : Int = 1;
    

	public function new( _nmegl : NMEGL) {

		lib = _nmegl;

		//NOTE : You cannot do anything before creating the actual window, which will call ready() for you when it is done		

	}

	public function ready() {

			// Init the shaders and view
		init();		

	}

        //Called each frame by NMEGL for logic (called before render)
	public function update() {


			//an awful magic number to change the value slowly
		red_value += red_direction * 0.005;

		if(red_value >= 1) {
			red_value = 1;
			red_direction = -red_direction;
		} else if(red_value <= 0) {
			red_value = 0;
			red_direction = -red_direction;
		}

	}

        //Called by NMEGL
	public function render() {

 			//Set the viewport for GL
 		GL.viewport( 0, 0, lib.config.width, lib.config.height );

            //Set the clear color to a weird color that bounces around
        GL.clearColor( red_value, red_value*0.5, red_value*0.3, 1);
        	//Clear the buffers
        GL.clear( GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT  );
                
            //Work out the middle of the viewport
        var positionX = lib.config.width / 2;
        var positionY = lib.config.height / 2;
        
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
	}


	public function init() {

			//Set up shaders
        createProgram();
        
        	//Create a set of vertices
        var vertices = [
            100, 	100, 	0,
            -100, 	100, 	0,
            100, 	-100, 	0,
            -100, 	-100, 	0
        ];
        	
        	//Create a buffer from OpenGL
        vertexBuffer = GL.createBuffer ();
        	//Bind it
        GL.bindBuffer (GL.ARRAY_BUFFER, vertexBuffer);  
        	//Point it to the vertex array!
        GL.bufferData (GL.ARRAY_BUFFER, new Float32Array (vertices), GL.STATIC_DRAW);

    }

		//Shader initialize

	private function createProgram ():Void {
        
        var vertexShaderSource = 
            
            "attribute vec3 vertexPosition;
            
            uniform mat4 modelViewMatrix;
            uniform mat4 projectionMatrix;
            
            void main(void) {
                gl_Position = projectionMatrix * modelViewMatrix * vec4(vertexPosition, 1.0);
            }";
        
        var vertexShader = GL.createShader (GL.VERTEX_SHADER);
        GL.shaderSource (vertexShader, vertexShaderSource);
        GL.compileShader (vertexShader);
        
        if (GL.getShaderParameter (vertexShader, GL.COMPILE_STATUS) == 0) {
            
            throw "Error compiling vertex shader";
            
        }
        
        var fragmentShaderSource = 
            
            "void main(void) {
                gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
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
        
        GL.useProgram (shaderProgram);
        vertexAttribute = GL.getAttribLocation (shaderProgram, "vertexPosition");
        GL.enableVertexAttribArray (vertexAttribute);
        
    }


}


