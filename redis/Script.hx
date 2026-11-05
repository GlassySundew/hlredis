package redis;

/** Builds one EVAL call with Redis keys before script arguments. */
class Script {

	final source : String;
	final keys : Array<String> = [];
	final arguments : Array<String> = [];

	public function new( source : String ) {

		if ( source == null )
			throw "Redis script cannot be null";
		this.source = source;
	}

	public function key( value : String ) : Script {

		if ( value == null )
			throw "Redis script key cannot be null";
		keys.push( value );
		return this;
	}

	public function arg( value : String ) : Script {

		if ( value == null )
			throw "Redis script argument cannot be null";
		arguments.push( value );
		return this;
	}

	public function invoke( client : Client ) : Reply {

		if ( client == null )
			throw "Redis script client cannot be null";
		return client.cmdArgs( ["EVAL", source, Std.string( keys.length )].concat( keys ).concat( arguments ) );
	}
}
