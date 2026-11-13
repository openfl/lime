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

	public function testNestedDispatchUsesMostRecentTimestamp():Void
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
				Assert.equals(200, event.timestamp);
			}
		});

		@:privateAccess event.__dispatchWithTimestamp(100, 1);
		Assert.same([100, 200], timestamps);
		Assert.equals(200, event.timestamp);
	}

	public function testOnceListenerAddedAheadDuringDispatch():Void
	{
		var event = new Event<Int->Void>();
		var calls:Array<String> = [];

		function later(_:Int):Void
		{
			calls.push("later");
		}

		var added = false;

		event.add(function(value)
		{
			calls.push("running " + value);

			if (!added)
			{
				added = true;
				event.add(later, true, 1);
			}
		});

		event.dispatch(1);
		Assert.same(["running 1"], calls);
		Assert.isTrue(event.has(later));

		event.dispatch(2);
		Assert.same(["running 1", "later", "running 2"], calls);
		Assert.isFalse(event.has(later));
	}

	public function testOnceListenerAddingAheadIsTheOneRemoved():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		function ahead():Void
		{
			calls.push("ahead");
		}

		function once():Void
		{
			calls.push("once");

			if (!event.has(ahead))
			{
				event.add(ahead, false, 1);
			}
		}

		event.add(once, true);
		event.dispatch();
		Assert.same(["once"], calls);
		Assert.isFalse(event.has(once));
		Assert.isTrue(event.has(ahead));

		event.dispatch();
		Assert.same(["once", "ahead"], calls);
	}

	public function testListenerAddedAheadDoesNotRepeatEarlierListeners():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];
		var added = false;

		event.add(function()
		{
			calls.push("first");
		}, false, 2);

		event.add(function()
		{
			calls.push("second");

			if (!added)
			{
				added = true;
				event.add(function()
				{
					calls.push("added");
				}, false, 3);
			}
		}, false, 1);

		event.add(function()
		{
			calls.push("third");
		});

		event.dispatch();
		Assert.same(["first", "second", "third"], calls);
	}

	public function testListenerAddedBehindRunsInSameDispatch():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];
		var added = false;

		event.add(function()
		{
			calls.push("first");

			if (!added)
			{
				added = true;
				event.add(function()
				{
					calls.push("added");
				});
			}
		});

		event.dispatch();
		Assert.same(["first", "added"], calls);
	}

	public function testListenerRemovingItselfDoesNotSkipNext():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		function first():Void
		{
			calls.push("first");
			event.remove(first);
		}

		event.add(first);
		event.add(function()
		{
			calls.push("second");
		});

		event.dispatch();
		Assert.same(["first", "second"], calls);
		Assert.isFalse(event.has(first));
	}

	public function testListenerRemovingEarlierListenerDoesNotRepeat():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		function first():Void
		{
			calls.push("first");
		}

		event.add(first);
		event.add(function()
		{
			calls.push("second");
			event.remove(first);
		});
		event.add(function()
		{
			calls.push("third");
		});

		event.dispatch();
		Assert.same(["first", "second", "third"], calls);
		Assert.isFalse(event.has(first));
	}

	public function testListenerExceptionKeepsDispatchTimestamp():Void
	{
		var event = new Event<Int->Void>();

		event.add(function(_)
		{
			throw "listener failure";
		});

		Assert.raises(function():Void
		{
			@:privateAccess event.__dispatchWithTimestamp(1234, 1);
		});

		Assert.equals(1234, event.timestamp);
	}

	public function testListenersReceiveTheDispatchedArguments():Void
	{
		var event = new Event<Int->String->Void>();
		var received:Array<String> = [];

		event.add(function(number, text)
		{
			received.push(number + text);
		});

		event.dispatch(1, "a");
		event.dispatch(2, "b");
		Assert.same(["1a", "2b"], received);
	}

	public function testHigherPriorityListenersRunFirst():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		event.add(function() calls.push("default"));
		event.add(function() calls.push("high"), false, 10);
		event.add(function() calls.push("low"), false, -10);
		event.add(function() calls.push("middle"), false, 5);

		event.dispatch();
		Assert.same(["high", "middle", "default", "low"], calls);
	}

	public function testEqualPriorityListenersRunInTheOrderAdded():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		event.add(function() calls.push("first"), false, 1);
		event.add(function() calls.push("second"));
		event.add(function() calls.push("third"), false, 1);
		event.add(function() calls.push("fourth"));
		event.add(function() calls.push("fifth"), false, 1);

		event.dispatch();
		Assert.same(["first", "third", "fifth", "second", "fourth"], calls);
	}

	public function testOnceListenerRunsForOneDispatchOnly():Void
	{
		var event = new Event<Int->Void>();
		var received:Array<Int> = [];

		function listener(value:Int):Void
		{
			received.push(value);
		}

		event.add(listener, true);
		Assert.isTrue(event.has(listener));

		event.dispatch(1);
		event.dispatch(2);
		Assert.same([1], received);
		Assert.isFalse(event.has(listener));
	}

	public function testOnceListenersKeepTheirPriority():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		event.add(function() calls.push("repeating"));
		event.add(function() calls.push("once"), true, 1);

		event.dispatch();
		event.dispatch();
		Assert.same(["once", "repeating", "repeating"], calls);
	}

	@Ignored("Waiting on #2145")
	public function testOnceListenerIsNotCalledAgainByANestedDispatch():Void
	{
		var event = new Event<Int->Void>();
		var received:Array<Int> = [];

		event.add(function(value)
		{
			received.push(value);

			if (value == 1)
			{
				event.dispatch(2);
			}
		}, true);

		event.dispatch(1);
		Assert.same([1], received);
	}

	public function testNestedDispatchRunsEveryListener():Void
	{
		var event = new Event<Int->Void>();
		var calls:Array<String> = [];

		event.add(function(value)
		{
			calls.push("first " + value);

			if (value == 1)
			{
				event.dispatch(2);
			}
		});

		event.add(function(value)
		{
			calls.push("second " + value);
		});

		event.dispatch(1);
		Assert.same(["first 1", "first 2", "second 2", "second 1"], calls);
	}

	public function testListenersRemovedDuringDispatchDoNotRun():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		function later():Void
		{
			calls.push("later");
		}

		event.add(function()
		{
			calls.push("first");
			event.remove(later);
		});
		event.add(function() calls.push("second"));
		event.add(later);

		event.dispatch();
		Assert.same(["first", "second"], calls);
		Assert.isFalse(event.has(later));
	}

	public function testOnceListenersRemovedDuringDispatchDoNotRun():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		function later():Void
		{
			calls.push("later");
		}

		event.add(function()
		{
			calls.push("first");
			event.remove(later);
		}, false, 1);
		event.add(later, true);

		event.dispatch();
		event.dispatch();
		Assert.same(["first", "first"], calls);
	}

	public function testRemoveAllDuringDispatchStopsTheRemainingListeners():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		event.add(function()
		{
			calls.push("first");
			event.removeAll();
		});
		event.add(function() calls.push("second"));
		event.add(function() calls.push("third"));

		event.dispatch();
		Assert.same(["first"], calls);

		event.dispatch();
		Assert.same(["first"], calls);
	}

	public function testHasOnlyFindsCurrentListeners():Void
	{
		var event = new Event<Void->Void>();

		function listener():Void {}
		function other():Void {}

		Assert.isFalse(event.has(listener));

		event.add(listener);
		Assert.isTrue(event.has(listener));
		Assert.isFalse(event.has(other));

		event.remove(listener);
		Assert.isFalse(event.has(listener));
	}

	public function testInstanceMethodsCanBeFoundAndRemoved():Void
	{
		var event = new Event<Void->Void>();
		var counter = new Counter();
		var otherCounter = new Counter();

		event.add(counter.count);
		Assert.isTrue(event.has(counter.count));
		Assert.isFalse(event.has(otherCounter.count), "the same method of another instance was found");

		// Removing the same method of another instance leaves this one
		event.remove(otherCounter.count);
		event.dispatch();
		Assert.equals(1, counter.calls);

		event.remove(counter.count);
		Assert.isFalse(event.has(counter.count));
		event.dispatch();
		Assert.equals(1, counter.calls);
		Assert.equals(0, otherCounter.calls);
	}

	public function testRemoveLeavesTheOtherListeners():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		function first():Void
		{
			calls.push("first");
		}

		function second():Void
		{
			calls.push("second");
		}

		function third():Void
		{
			calls.push("third");
		}

		function neverAdded():Void {}

		event.add(first);
		event.add(second, false, -1);
		event.add(third, false, -2);
		event.remove(second);
		event.remove(neverAdded);

		event.dispatch();
		Assert.same(["first", "third"], calls);
		Assert.isTrue(event.has(first));
		Assert.isTrue(event.has(third));
	}

	public function testRemoveAllRemovesEveryListener():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		function repeating():Void
		{
			calls.push("repeating");
		}

		function once():Void
		{
			calls.push("once");
		}

		event.add(repeating);
		event.add(once, true, 1);
		event.removeAll();

		event.dispatch();
		Assert.same([], calls);
		Assert.isFalse(event.has(repeating));
		Assert.isFalse(event.has(once));

		// The event is still usable afterwards
		event.add(repeating);
		event.dispatch();
		Assert.same(["repeating"], calls);
	}

	public function testCancelStopsTheRemainingListeners():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		Assert.isFalse(event.canceled);

		event.add(function() calls.push("high"), false, 2);
		event.add(function()
		{
			calls.push("canceling");
			event.cancel();
		}, false, 1);
		event.add(function() calls.push("low"));

		event.dispatch();
		Assert.same(["high", "canceling"], calls);
		Assert.isTrue(event.canceled);
	}

	public function testNextDispatchIsNotCanceled():Void
	{
		var event = new Event<Bool->Void>();
		var calls:Array<String> = [];

		event.add(function(cancel)
		{
			calls.push("first");

			if (cancel)
			{
				event.cancel();
			}
		});
		event.add(function(_) calls.push("second"));

		event.dispatch(true);
		Assert.isTrue(event.canceled);

		event.dispatch(false);
		Assert.isFalse(event.canceled);
		Assert.same(["first", "first", "second"], calls);
	}

	public function testOnceListenerThatCancelsIsStillRemoved():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];

		function stop():Void
		{
			calls.push("stop");
			event.cancel();
		}

		event.add(stop, true, 1);
		event.add(function() calls.push("after"));

		event.dispatch();
		Assert.same(["stop"], calls);
		Assert.isFalse(event.has(stop));

		event.dispatch();
		Assert.same(["stop", "after"], calls);
	}

	public function testListenerExceptionLeavesTheEventUsable():Void
	{
		var event = new Event<Void->Void>();
		var calls:Array<String> = [];
		var fail = true;

		event.add(function()
		{
			calls.push("first");

			if (fail)
			{
				throw "listener failure";
			}
		});
		event.add(function() calls.push("second"));

		Assert.raises(function():Void
		{
			event.dispatch();
		});

		fail = false;
		event.dispatch();
		Assert.same(["first", "first", "second"], calls);
	}

	@Ignored("Waiting on #2145")
	public function testOnceListenerThatThrowsIsStillRemoved():Void
	{
		var event = new Event<Void->Void>();
		var calls = 0;

		function failing():Void
		{
			calls++;
			throw "listener failure";
		}

		event.add(failing, true);

		Assert.raises(function():Void
		{
			event.dispatch();
		});

		Assert.isFalse(event.has(failing), "a once listener that threw is still a listener");

		try
		{
			event.dispatch();
		}
		catch (e:Dynamic) {}

		Assert.equals(1, calls);
	}

	// The docs don't say whether adding a listener again adds it twice, but
	// either way it is a listener until it is removed
	public function testListenerAddedTwiceIsGoneAfterOneRemove():Void
	{
		var event = new Event<Void->Void>();
		var calls = 0;

		function listener():Void
		{
			calls++;
		}

		event.add(listener);
		event.add(listener);
		event.remove(listener);

		Assert.isFalse(event.has(listener));
		event.dispatch();
		Assert.equals(0, calls);
	}
}

private class Counter
{
	public var calls:Int = 0;

	public function new() {}

	public function count():Void
	{
		calls++;
	}
}
