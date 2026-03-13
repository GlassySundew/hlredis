package redis;

class Client {

	var h : Dynamic;

	public function new( host : String, port : Int ) {

		h = Redis.redis_connect( @:privateAccess host.toUtf8(), port );
		if ( h == null )
			throw "Redis connect failed";
	}

	public function auth( password : String ) : Bool {

		return Redis.redis_auth( h, @:privateAccess password.toUtf8() );
	}

	public function select( db : Int ) : Bool {

		return Redis.redis_select( h, db );
	}

	public function cmd( command : String ) : Reply {

		var r = Redis.redis_cmd( h, @:privateAccess command.toUtf8() );
		if ( r == null )
			throw "Redis command failed";

		return new Reply( r );
	}

	public function close() : Void {

		Redis.redis_close( h );
	}
}
