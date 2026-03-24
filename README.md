# hashlink/c redis bindings

## Compilation
* Place repo at your `hashlink/libs` directory

### Platform
##### Windows
 * run `build.bat` at repo root
##### Linux
 * make sure to install hiredis dev `sudo apt install libhiredis-dev` for ubuntu
 * run `make` inside repo root

## Pub/Sub
Use a dedicated subscriber connection when listening for events, because a Redis connection in subscribed mode is effectively reserved for pub/sub traffic.

```haxe
var sub = new redis.Client( "127.0.0.1", 6379 );
sub.subscribe( "events" );

var pub = new redis.Client( "127.0.0.1", 6379 );
pub.publish( "events", "hello" );

while ( true ) {
	var msg = sub.receiveMessage();
	if ( msg.kind == "message" ) {
		trace( msg.channel + ": " + msg.payload );
	}
}
```

You can also connect with a Redis URL. When using URL form, the client will automatically apply password auth and DB selection:

```haxe
var client = new redis.Client( "redis://:secret@127.0.0.1:6379/2" );
```

Available helpers:
* `publish( channel, message ) : Int`
* `subscribe( channel ) : Void`
* `unsubscribe( channel ) : Void`
* `receiveReply() : Reply`
* `receiveMessage() : PubSubMessage`
* `pipeline() : Pipeline`

## Pipeline
Pipelines batch commands onto a single connection and then drain their replies in order when `exec()` is called.

```haxe
client.pipeline()
	.hset( "mmo:instance:1", "state", "Starting" )
	.expire( "mmo:instance:1", 30 )
	.sadd( "mmo:instances:Starting", "1" )
	.exec( function( success ) {
		trace( success );
	} );
```

Available pipeline helpers:
* `hset( key, field, value ) : Pipeline`
* `expire( key, ttlSeconds ) : Pipeline`
* `sadd( key, value ) : Pipeline`
* `srem( key, value ) : Pipeline`
* `del( key ) : Pipeline`
* `exec( onDone ) : Void`
