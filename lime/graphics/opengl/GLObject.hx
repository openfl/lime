package lime.graphics.opengl;


class GLObject {
        
        /** The native GL handle/id. read only */
    public var id (default, null) : Dynamic;
        /** The invalidated state. read only */
    public var invalidated (get, null) : Bool;
        /** The valid state. read only */
    public var valid (get, null) : Bool;
    
    var version:Int;
        
    public function new (version:Int, id:Dynamic) {
        
        this.version = version;
        this.id = id;
        
    } //new

    function getType() : String {
        return "GLObject";
    } //getType
    
    public function invalidate() : Void {
        id = null;
    } //invalidate
    
    public function isValid() : Bool {
        return id != null && version == GL.version;
    } //isValid
    
    public function isInvalid() : Bool {
        return !isValid ();
    } //isInvalid
    
    public function toString() : String {
        return getType() + "(" + id + ")";
    } //toString
    
// Getters & Setters
    
    function get_invalidated() : Bool {
        return isInvalid ();
    } //get_invalidated
    
    function get_valid() : Bool {
        return isValid ();
    } //get_valid
    
}