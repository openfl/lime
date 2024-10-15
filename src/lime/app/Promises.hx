package lime.app;

import lime.app.Promise;
import lime.app.Future;

/**
 * A set of static utility functions for working with Promises.
 * This includes functions which resolve groups of Futures.
 */
class Promises {
  /**
   * Creates a promise which fulfills when all the input promises resolve successfully,
   * with an array of the result values.
   * Rejects when any of the input promises reject, with the first rejection reason.
   * @param futures A list of Futures to resolve.
   * @return A Future for a list of result values.
   */
  public static function all<T>(futures:Array<Future<T>>):Future<Array<T>> {
    var promise:Promise<Array<T>> = new Promise<Array<T>>();
    var results:Array<T> = [];

    for (future in futures) {
      future.onComplete(function(result) {
        results.push(result);
        if (results.length == futures.length) {
          promise.complete(results);
        }
      });
      future.onError(function(error) {
        promise.error(error);
      });
    }

    return promise.future;
  }

  /**
   * Creates a promise which fulfills when all the input promises settle (whether success or failure).
   * Returns an array of objects that describe the outcome of each promise.
   * @param futures A list of Futures to resolve.
   * @return A Future for a list of result values.
   */
  public static function allSettled<T>(futures:Array<Future<T>>):Future<Array<Future<T>>> {
    var promise:Promise<Array<Future<T>>> = new Promise<Array<Future<T>>>();

    var resolved:Int = 0;

    for (future in futures) {
      future.onComplete(function(value) {
        resolved += 1;
        if (resolved == futures.length) {
          promise.complete(futures);
        }
      });
      future.onError(function(error) {
        resolved += 1;
        if (resolved == futures.length) {
          promise.complete(futures);
        }
      });
    }

    return promise.future;
  }

  /**
   * Creates a promise which fulfills when any of the input promises resolve successfully.
   * Returns the first fulfilled promise. If all promises reject, the promise will be rejected with the list of rejection reasons.
   * @param futures A list of Futures to resolve.
   * @return A Future for a result value.
   */
  public static function any<T>(futures:Array<Future<T>>):Future<T> {
    var promise:Promise<T> = new Promise<T>();
    var errors:Array<Dynamic> = [];

    for (future in futures) {
      future.onComplete(function(value) {
        promise.complete(value);
      });
      future.onError(function(error) {
        errors.push(error);
        if (errors.length == futures.length) {
          promise.error(errors);
        }
      });
    }

    return promise.future;
  }

  /**
   * Creates a promise which fulfills when any of the input promises settle.
   * Returns an object that describes the outcome of the first settled promise (whether success or failure).
   * @param futures A list of Futures to resolve.
   * @return A Future for a result value.
   */
  public static function race<T>(futures:Array<Future<T>>):Future<T> {
    var promise:Promise<T> = new Promise<T>();
    for (future in futures) {
      future.onComplete(function(value) {
        promise.complete(value);
      });
      future.onError(function(error) {
        promise.error(error);
      });
    }
    return promise.future;
  }
}
