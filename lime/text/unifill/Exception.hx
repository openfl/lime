package lime.text.unifill;

class Exception {
	function new() {
	}
	public function toString() : String {
		throw null;
	}
}

class InvalidCodePoint extends Exception {
	public var code(default, null) : Int;
	public function new(code : Int) {
		super();
		this.code = code;
	}
	override public function toString() : String {
		return 'InvalidCodePoint(code: $code)';
	}
}

class InvalidCodeUnitSequence extends Exception {
	public var index(default, null) : Int;
	public function new(index : Int) {
		super();
		this.index = index;
	}
	override public function toString() : String {
		return 'InvalidCodeUnitSequence(index: $index)';
	}
}
