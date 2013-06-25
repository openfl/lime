package lime.utils;


@:arrayAccess abstract Vector<T>(Array<T>) {
    
    
    public var length (get, set):Int;
    public var fixed (get, set):Bool;
    
    
    public function new (?length:Int, ?fixed:Bool):Void {
        
        this = new Array<T> ();
        
    }
    
    
    public function concat (?a:Array<T>):Vector<T> {
        
        return cast this.concat (a);
        
    }
    
    
    public function copy ():Vector<T> {
        
        return this.copy ();
        
    }
    
    
    public function iterator<T> ():Iterator<T> {
        
        return this.iterator ();
        
    }
    
    
    public function join (sep:String):String {
        
        return this.join (sep);
        
    }
    
    
    public function pop ():Null<T> {
        
        return this.pop ();
        
    }
    
    
    public function push (x:T):Int {
        
        return this.push (x);
        
    }
    
    
    public function reverse ():Void {
        
        this.reverse ();
        
    }
    
    
    public function shift ():Null<T> {
        
        return this.shift ();
        
    }
    
    
    public function unshift (x:T):Void {
        
        this.unshift (x);
        
    }
    
    
    public function slice (?pos:Int, ?end:Int):Vector<T> {
        
        return cast this.slice (pos, end);
        
    }
    
    
    public function sort (f:T -> T -> Int):Void {
        
        this.sort (f);
        
    }
    
    
    public function splice (pos:Int, len:Int):Vector<T> {
        
        return cast this.splice (pos, len);
        
    }
    
    
    public function toString ():String {
        
        return this.toString ();
        
    }
    
    
    public function indexOf (x:T, ?from:Int = 0):Int {
        
        for (i in from...this.length) {
            
            if (this[i] == x) {
                
                return i;
                
            }
            
        }
        
        return -1;
        
    }
    
    
    public function lastIndexOf (x:T, ?from:Int = 0):Int {
        
        var i = this.length - 1;
        
        while (i >= from) {
            
            if (this[i] == x) return i;
            i--;
            
        }
        
        return -1;
        
    }
    
    
    public inline static function ofArray<T> (a:Array<Dynamic>):Vector<T> {
        
        return new Vector<T> ().concat (cast a);
        
    }
    
    
    public inline static function convert<T,U> (v:Array<T>):Vector<U> {
        
        return cast v;
        
    }
    
    
    @:from static public inline function fromArray<T, U> (a:Array<U>):Vector<T> {
        
        return cast a;
        
    }
    
    
    @:to public inline function toArray<T> ():Array<T> {
        
        return this;
        
    }
    
    
    
    
    // Getters & Setters
    
    
    
    
    private function get_length ():Int {
        
        return this.length;
        
    }
    
    
    private function set_length (value:Int):Int {
        
        return value;
        
    }
    
    
    private function get_fixed ():Bool {
        
        return false;
        
    }
    
    
    private function set_fixed (value:Bool):Bool {
        
        return value;
        
    }
    
    
}
