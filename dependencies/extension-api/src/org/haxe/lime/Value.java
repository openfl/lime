package org.haxe.lime;


public class Value {
	
	
	double mValue;
	
	public Value (double inValue) { mValue = inValue; }
	public Value (int inValue) { mValue = inValue; }
	public Value (short inValue) { mValue = inValue; }
	public Value (char inValue) { mValue = inValue; }
	public Value (boolean inValue) { mValue = inValue ? 1.0 : 0.0; }
	
	public double getDouble () { return mValue; }
	
	
}