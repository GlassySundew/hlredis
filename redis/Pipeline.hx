package redis;

class Pipeline {

	var h : Dynamic;
	var queued : Int = 0;

	public function new( h : Dynamic ) {
		this.h = h;
	}

	public function hset( key : String, field : String, value : Dynamic ) : Pipeline {

		appendOrThrow(
			Redis.redis_append_hset(
				h,
				@:privateAccess key.toUtf8(),
				@:privateAccess field.toUtf8(),
				@:privateAccess Std.string( value ).toUtf8()
			),
			"HSET"
		);
		return this;
	}

	public function expire( key : String, ttlSeconds : Int ) : Pipeline {

		appendOrThrow( Redis.redis_append_expire( h, @:privateAccess key.toUtf8(), ttlSeconds ), "EXPIRE" );
		return this;
	}

	public function sadd( key : String, value : Dynamic ) : Pipeline {

		appendOrThrow(
			Redis.redis_append_sadd( h, @:privateAccess key.toUtf8(), @:privateAccess Std.string( value ).toUtf8() ),
			"SADD"
		);
		return this;
	}

	public function srem( key : String, value : Dynamic ) : Pipeline {

		appendOrThrow(
			Redis.redis_append_srem( h, @:privateAccess key.toUtf8(), @:privateAccess Std.string( value ).toUtf8() ),
			"SREM"
		);
		return this;
	}

	public function del( key : String ) : Pipeline {

		appendOrThrow( Redis.redis_append_del( h, @:privateAccess key.toUtf8() ), "DEL" );
		return this;
	}

	public function exec( onDone : Bool -> Void ) : Void {

		var success = true;

		try {
			for ( i in 0...queued ) {
				var handle = Redis.redis_get_reply( h );
				if ( handle == null ) {
					success = false;
					continue;
				}

				var reply = new Reply( handle );
				if ( reply.type() == Reply.ERROR )
					success = false;
				reply.free();
			}
		} catch ( e ) {
			success = false;
		}

		queued = 0;
		onDone( success );
	}

	inline function appendOrThrow( ok : Bool, command : String ) : Void {

		if ( !ok )
			throw "Redis pipeline append failed: " + command;
		queued++;
	}
}
