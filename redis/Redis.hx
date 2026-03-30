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

	public static function redis_set_bytes( handle : RedisHandle, key : hl.Bytes, value : hl.Bytes, valueLen : Int ) : Bool {
		return false;
	}

	public static function redis_hget_bytes( handle : RedisHandle, key : hl.Bytes, field : hl.Bytes ) : RedisReplyHandle {
		return null;
	}

	public static function redis_append_hset( handle : RedisHandle, key : hl.Bytes, field : hl.Bytes, value : hl.Bytes ) : Bool {
		return false;
	}

	public static function redis_append_hset_bytes( handle : RedisHandle, key : hl.Bytes, field : hl.Bytes, value : hl.Bytes, valueLen : Int ) : Bool {
		return false;
	}

	public static function redis_append_set_bytes( handle : RedisHandle, key : hl.Bytes, value : hl.Bytes, valueLen : Int ) : Bool {
		return false;
	}

	public static function redis_append_expire( handle : RedisHandle, key : hl.Bytes, ttlSeconds : Int ) : Bool {
		return false;
	}

	public static function redis_append_sadd( handle : RedisHandle, key : hl.Bytes, value : hl.Bytes ) : Bool {
		return false;
	}

	public static function redis_append_srem( handle : RedisHandle, key : hl.Bytes, value : hl.Bytes ) : Bool {
		return false;
	}

	public static function redis_append_del( handle : RedisHandle, key : hl.Bytes ) : Bool {
		return false;
	}

	public static function redis_subscribe( handle : RedisHandle, channel : hl.Bytes ) : Bool {
		return false;
	}

	public static function redis_unsubscribe( handle : RedisHandle, channel : hl.Bytes ) : Bool {
		return false;
	}

	public static function redis_publish( handle : RedisHandle, channel : hl.Bytes, message : hl.Bytes ) : Int {
		return 0;
	}

	public static function redis_get_reply( handle : RedisHandle ) : RedisReplyHandle {
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
