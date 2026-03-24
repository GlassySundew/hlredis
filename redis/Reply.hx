package redis;

class Reply {

	public static final STRING = 1;
	public static final ARRAY = 2;
	public static final INTEGER = 3;
	public static final NIL = 4;
	public static final STATUS = 5;
	public static final ERROR = 6;

	var h : Dynamic;

	public function new( h ) {
		this.h = h;
	}

	public function type() : Int {

		return Redis.redis_reply_type( h );
	}

	public function asString() : Null<String> {

		var b = Redis.redis_reply_string( h );
		return b == null ? null : @:privateAccess String.fromUTF8( b );
	}

	public function asInt() : Int {

		return Redis.redis_reply_int( h );
	}

	public function length() : Int {

		return Redis.redis_reply_len( h );
	}

	public function at( i : Int ) : Reply {

		return new Reply( Redis.redis_reply_at( h, i ) );
	}

	public function free() : Void {

		Redis.redis_reply_free( h );
	}
}
