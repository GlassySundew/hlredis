package redis;

private typedef RedisHandle = hl.Abstract<"hl_redis">;
private typedef RedisReplyHandle = hl.Abstract<"hl_redis_reply">;

@:hlNative( "redis" )
class Redis {

	public static function redis_connect( host : hl.Bytes, port : Int ) : RedisHandle {
		return null;
	}

	public static function redis_auth( handle : RedisHandle, password : hl.Bytes ) : Bool {
		return false;
	}

	public static function redis_select( handle : RedisHandle, db : Int ) : Bool {
		return false;
	}

	public static function redis_close( handle : RedisHandle ) : Void {}

	public static function redis_cmd( handle : RedisHandle, cmd : hl.Bytes ) : RedisReplyHandle {
		return null;
	}

	public static function redis_reply_type( reply : RedisReplyHandle ) : Int {
		return 0;
	}

	public static function redis_reply_string( reply : RedisReplyHandle ) : hl.Bytes {
		return null;
	}

	public static function redis_reply_len( reply : RedisReplyHandle ) : Int {
		return 0;
	}

	public static function redis_reply_int( reply : RedisReplyHandle ) : Int {
		return 0;
	}

	public static function redis_reply_at( reply : RedisReplyHandle, idx : Int ) : RedisReplyHandle {
		return null;
	}

	public static function redis_reply_free( reply : RedisReplyHandle ) : Void {}
}
