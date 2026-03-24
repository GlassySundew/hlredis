package redis;

class PubSubMessage {

	public var kind(default, null) : String;
	public var channel(default, null) : Null<String>;
	public var payload(default, null) : Null<String>;
	public var pattern(default, null) : Null<String>;
	public var subscriptionCount(default, null) : Null<Int>;

	public function new( kind : String, ?channel : String, ?payload : String, ?pattern : String, ?subscriptionCount : Int ) {

		this.kind = kind;
		this.channel = channel;
		this.payload = payload;
		this.pattern = pattern;
		this.subscriptionCount = subscriptionCount;
	}

	public static function fromReply( reply : Reply ) : PubSubMessage {

		if ( reply == null || reply.type() != Reply.ARRAY || reply.length() < 3 )
			throw "Invalid Redis pub/sub reply";

		var kind = reply.at( 0 ).asString();
		if ( kind == null )
			throw "Invalid Redis pub/sub reply";

		return switch ( kind ) {
			case "subscribe", "unsubscribe", "psubscribe", "punsubscribe":
				new PubSubMessage( kind, reply.at( 1 ).asString(), null, null, reply.at( 2 ).asInt() );
			case "message":
				new PubSubMessage( kind, reply.at( 1 ).asString(), reply.at( 2 ).asString() );
			case "pmessage":
				if ( reply.length() < 4 )
					throw "Invalid Redis pattern pub/sub reply";
				new PubSubMessage( kind, reply.at( 2 ).asString(), reply.at( 3 ).asString(), reply.at( 1 ).asString() );
			default:
				throw "Unsupported Redis pub/sub reply type: " + kind;
		}
	}
}
