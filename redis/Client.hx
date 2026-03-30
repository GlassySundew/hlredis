package redis;

class Client {

	static function parseConnectionConfig( hostOrUrl : String, port : Null<Int> ) : {
		host : String,
		port : Int,
		password : Null<String>,
		db : Null<Int>
	} {

		if ( !StringTools.startsWith( hostOrUrl, "redis://" ) ) {
			if ( port == null )
				throw "Redis port is required when using host/port constructor";

			return {
				host : hostOrUrl,
				port : port,
				password : null,
				db : null
			};
		}

		var rest = hostOrUrl.substr( "redis://".length );
		var slashIdx = rest.indexOf( "/" );
		var authority = slashIdx == -1 ? rest : rest.substr( 0, slashIdx );
		var path = slashIdx == -1 ? "" : rest.substr( slashIdx + 1 );
		var atIdx = authority.lastIndexOf( "@" );
		var userInfo = atIdx == -1 ? null : authority.substr( 0, atIdx );
		var hostPort = atIdx == -1 ? authority : authority.substr( atIdx + 1 );
		var parsedHost = hostPort;
		var parsedPort : Null<Int> = 6379;
		var parsedPassword : Null<String> = null;
		var parsedDb : Null<Int> = null;

		if ( userInfo != null && userInfo != "" ) {
			var colonIdx = userInfo.indexOf( ":" );
			var passwordPart = colonIdx == -1 ? userInfo : userInfo.substr( colonIdx + 1 );
			parsedPassword = StringTools.urlDecode( passwordPart );
		}

		if ( StringTools.startsWith( hostPort, "[" ) ) {
			var endBracket = hostPort.indexOf( "]" );
			if ( endBracket == -1 )
				throw "Invalid Redis URL";

			parsedHost = hostPort.substr( 1, endBracket - 1 );
			if ( endBracket + 1 < hostPort.length ) {
				if ( hostPort.charAt( endBracket + 1 ) != ":" )
					throw "Invalid Redis URL";

				parsedPort = Std.parseInt( hostPort.substr( endBracket + 2 ) );
			}
		} else {
			var colonIdx = hostPort.lastIndexOf( ":" );
			if ( colonIdx > -1 ) {
				parsedHost = hostPort.substr( 0, colonIdx );
				parsedPort = Std.parseInt( hostPort.substr( colonIdx + 1 ) );
			}
		}

		if ( parsedHost == "" )
			throw "Redis host is required";

		if ( path != "" ) {
			var dbPart = path.split( "/" )[0];
			if ( dbPart != "" ) {
				parsedDb = Std.parseInt( dbPart );
				if ( parsedDb == null )
					throw "Invalid Redis database index";
			}
		}

		if ( parsedPort == null )
			throw "Invalid Redis port";

		return {
			host : StringTools.urlDecode( parsedHost ),
			port : parsedPort,
			password : parsedPassword,
			db : parsedDb
		};
	}

	var h : Dynamic;

	public function new( hostOrUrl : String, ?port : Int ) {

		var cfg = parseConnectionConfig( hostOrUrl, port );

		h = Redis.redis_connect( @:privateAccess cfg.host.toUtf8(), cfg.port );
		if ( h == null )
			throw "Redis connect failed";

		if ( cfg.password != null && !auth( cfg.password ) ) {
			close();
			throw "Redis auth failed";
		}

		if ( cfg.db != null && !select( cfg.db ) ) {
			close();
			throw "Redis select failed";
		}
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

	public function setBytes( key : String, value : haxe.io.Bytes ) : Bool {

		return Redis.redis_set_bytes(
			h, @:privateAccess key.toUtf8(),
			value.getData().bytes,
			value.length
		);
	}

	public function hgetBytes( key : String, field : String ) : Null<haxe.io.Bytes> {

		var r = Redis.redis_hget_bytes(
			h, @:privateAccess key.toUtf8(), @:privateAccess field.toUtf8()
		);
		if ( r == null )
			throw "Redis HGET failed";

		var reply = new Reply( r );
		try {

			var result = switch ( reply.type() ) {
				case Reply.NIL: null;
				case Reply.STRING, Reply.STATUS: reply.asBytes();
				case Reply.ERROR: throw reply.asString();
				default: throw "Unexpected Redis reply type: " + reply.type();
			}
			reply.free();
			return result;
		} catch ( e ) {

			reply.free();
			throw e;
		}
	}

	public function publish( channel : String, message : String ) : Int {

		var delivered = Redis.redis_publish( h, @:privateAccess channel.toUtf8(), @:privateAccess message.toUtf8() );
		if ( delivered < 0 )
			throw "Redis publish failed";

		return delivered;
	}

	public function subscribe( channel : String ) : Void {

		if ( !Redis.redis_subscribe( h, @:privateAccess channel.toUtf8() ) )
			throw "Redis subscribe failed";
	}

	public function unsubscribe( channel : String ) : Void {

		if ( !Redis.redis_unsubscribe( h, @:privateAccess channel.toUtf8() ) )
			throw "Redis unsubscribe failed";
	}

	public function receiveReply() : Reply {

		var r = Redis.redis_get_reply( h );
		if ( r == null )
			throw "Redis receive failed";

		return new Reply( r );
	}

	public function receiveMessage() : PubSubMessage {

		return PubSubMessage.fromReply( receiveReply() );
	}

	public function pipeline() : Pipeline {

		return new Pipeline( h );
	}

	public function close() : Void {

		Redis.redis_close( h );
	}
}
