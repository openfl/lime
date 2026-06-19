package app;

import lime.app.Event;
import lime.system.System;
import utest.Assert;
import utest.Test;

class EventTest extends Test
{
	public function new()
	{
		super();
	}

	public function testTimestampUsesDispatchTime():Void
	{
		var event = new Event<Int->Void>();
		var observed = -1;
		var before = System.getTimer();

		event.add(function(_)
		{
			observed = event.timestamp;
		});

		event.dispatch(1);
		var after = System.getTimer();

		Assert.isTrue(observed >= before);
		Assert.isTrue(observed <= after);
	}

	public function testExplicitTimestampIsVisible():Void
	{
		var event = new Event<Int->Void>();
		var observed = -1;

		event.add(function(_)
		{
			observed = event.timestamp;
		});

		@:privateAccess event.__dispatchWithTimestamp(1234, 1);
		Assert.equals(1234, observed);
	}

	public function testNestedDispatchRestoresTimestamp():Void
	{
		var event = new Event<Int->Void>();
		var timestamps:Array<Int> = [];
		var nested = false;

		event.add(function(_)
		{
			timestamps.push(event.timestamp);

			if (!nested)
			{
				nested = true;
				@:privateAccess event.__dispatchWithTimestamp(200, 2);
				Assert.equals(100, event.timestamp);
			}
		});

		@:privateAccess event.__dispatchWithTimestamp(100, 1);
		Assert.same([100, 200], timestamps);
	}
}
