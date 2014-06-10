package lime.graphics.opengl;


class GLProgram extends GLObject {
        
    public var shaders:Array<GLShader>;
    
    public function new( version:Int, id:Dynamic ) {

        super (version, id);
        shaders = new Array<GLShader> ();

    } //new
    
    public function attach( shader:GLShader ) : Void {
        shaders.push(shader);
    } //attach
    
    public function getShaders() : Array<GLShader> {
        return shaders.copy();
    } //getShaders
    
    override function getType ():String {
        return "Program";
    } //getType

} //GLProgram