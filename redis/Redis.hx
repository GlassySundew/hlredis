package redis;

@:hlNative( "redis" )
class Redis {

	public static function redis_connect( host : hl.Bytes, port : Int ) : Dynamic {
		return null;
	}

	public static function redis_auth( handle : Dynamic, password : hl.Bytes ) : Bool {
		return false;
	}

	public static function redis_select( handle : Dynamic, db : Int ) : Bool {
		return false;
	}

	public static function redis_close( handle : Dynamic ) : Void {}

	public static function redis_cmd( handle : Dynamic, cmd : hl.Bytes ) : Dynamic {
		return null;
	}

	public static function redis_reply_type( reply : Dynamic ) : Int {
		return 0;
	}

	public static function redis_reply_string( reply : Dynamic ) : hl.Bytes {
		return null;
	}

	public static function redis_reply_len( reply : Dynamic ) : Int {
		return 0;
	}

	public static function redis_reply_int( reply : Dynamic ) : Int {
		return 0;
	}

	public static function redis_reply_at( reply : Dynamic, idx : Int ) : Dynamic {
		return null;
	}

	public static function redis_reply_free( reply : Dynamic ) : Void {}
}
