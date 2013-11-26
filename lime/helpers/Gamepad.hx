package lime.helpers;

class Gamepad {

	public var max_buttons : Int = 16;
	public var max_axis : Int = 8;
	public var max_hats : Int = 8;

	public var button0 : Int = -1;
	public var button1 : Int = -1;
	public var button2 : Int = -1;
	public var button3 : Int = -1;
	public var button4 : Int = -1;
	public var button5 : Int = -1;
	public var button6 : Int = -1;
	public var button7 : Int = -1;
	public var button8 : Int = -1;
	public var button9 : Int = -1;
	public var button10 : Int = -1;
	public var button11 : Int = -1;
	public var button12 : Int = -1;
	public var button13 : Int = -1;
	public var button14 : Int = -1;
	public var button15 : Int = -1;

	public var axis0 : Int = -1;
	public var axis1 : Int = -1;
	public var axis2 : Int = -1;
	public var axis3 : Int = -1;
	public var axis4 : Int = -1;
	public var axis5 : Int = -1;
	public var axis6 : Int = -1;
	public var axis7 : Int = -1;

	public var hat0 : Int = -1;
	public var hat1 : Int = -1;
	public var hat2 : Int = -1;
	public var hat3 : Int = -1;
	public var hat4 : Int = -1;
	public var hat5 : Int = -1;
	public var hat6 : Int = -1;
	public var hat7 : Int = -1;

    public function new() {}
    public function set_profile(buttons:Array<Int>, axis:Array<Int>, hats:Array<Int> ) {

    	for(i in 0 ... max_buttons) {    	
    		Reflect.setProperty(this, 'button' + i, buttons[i]);
    	}

    	for(i in 0 ... max_axis) {
    		Reflect.setProperty(this, 'axis' + i, axis[i]);
    	}

    	for(i in 0 ... max_hats) {
    		Reflect.setProperty(this, 'hat' + i, hats[i]);
    	}

    } //set_profile

    public function apply_360_profile() {

    	var buttons : Array<Int> = [];
    	var axis : Array<Int> = [];
    	var hats : Array<Int> = [];

    	#if mac
    					//A B X Y RB LB RS LS back start guide
    		buttons = 	[11,12,13,14,8,9,7,6,5,4,10,-1,-1,-1,-1,-1];
    					//LSY LSX RSY RSX LT RT
    		axis = 		[0,1,2,3,4,5,-1,-1];
    					//UP DOWN LEFT RIGHT
    		hats = 		[0,1,2,3,-1,-1,-1,-1];
    	#end
    	#if windows
    					//A B X Y  RB LB RS LS  back start guide
    		buttons = 	[0,1,2,3, 5,4,9,8, 6,7,-1, -1,-1,-1,-1,-1];
    					//LSY LSX RSY RSX LT RT
    		axis = 		[1,0,3,4,2,2,-1,-1];
    					//0 0 0 0
    		hats = 		[0,0,0,0,-1,-1,-1,-1];	    	
    	#end
    	#if linux
    		buttons = 	[-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1];
    		axis = 		[-1,-1,-1,-1,-1,-1,-1,-1];
    		hats = 		[-1,-1,-1,-1,-1,-1,-1,-1];
    	#end
    	#if lime_html5
    		buttons = 	[-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1];
    		axis = 		[-1,-1,-1,-1,-1,-1,-1,-1];
    		hats = 		[-1,-1,-1,-1,-1,-1,-1,-1];
    	#end

    		//apply it
    	set_profile(buttons, axis, hats);

    } // apply_360_profile


}