#define HL_NAME(n) redis_##n

#include <hl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#if defined(__has_include)
#  if __has_include(<hiredis/hiredis.h>)
#    include <hiredis/hiredis.h>
#  elif __has_include(<hiredis.h>)
#    include <hiredis.h>
#  else
#    error "Could not find hiredis headers"
#  endif
#else
#  include <hiredis/hiredis.h>
#endif

typedef struct hl_redis {
    void (*finalize)(struct hl_redis*);
    redisContext* ctx;
} hl_redis;

typedef struct hl_redis_reply {
    void (*finalize)(struct hl_redis_reply*);
    redisReply* r;
    int owner;
} hl_redis_reply;

#define _REDIS _ABSTRACT(hl_redis)
#define _REDIS_REPLY _ABSTRACT(hl_redis_reply)

static void redis_handle_finalizer(hl_redis* h) {
    if (h && h->ctx) {
        redisFree(h->ctx);
        h->ctx = NULL;
    }
}

static void reply_handle_finalizer(hl_redis_reply* h) {
    if (h && h->r && h->owner) {
        freeReplyObject(h->r);
        h->r = NULL;
    }
}

HL_PRIM hl_redis* HL_NAME(redis_connect)(vbyte* host, int port) {
    redisContext* ctx = redisConnect((const char*)host, port);
    if (!ctx || ctx->err) {
        if (ctx) redisFree(ctx);
        return NULL;
    }

    hl_redis* h = (hl_redis*)hl_gc_alloc_finalizer(sizeof(hl_redis));
    h->finalize = redis_handle_finalizer;
    h->ctx = ctx;
    return h;
}

HL_PRIM bool HL_NAME(redis_auth)(hl_redis* c, vbyte* password) {
    if (!c || !c->ctx) return false;
    redisReply* r = (redisReply*)redisCommand(c->ctx, "AUTH %s", (const char*)password);
    if (!r) return false;
    int ok = (r->type == REDIS_REPLY_STATUS);
    freeReplyObject(r);
    return ok;
}

HL_PRIM bool HL_NAME(redis_select)(hl_redis* c, int db) {
    if (!c || !c->ctx) return false;
    redisReply* r = (redisReply*)redisCommand(c->ctx, "SELECT %d", db);
    if (!r) return false;
    int ok = (r->type == REDIS_REPLY_STATUS);
    freeReplyObject(r);
    return ok;
}

HL_PRIM void HL_NAME(redis_close)(hl_redis* c) {
    if (!c || !c->ctx) return;
    redisFree(c->ctx);
    c->ctx = NULL;
}

HL_PRIM hl_redis_reply* HL_NAME(redis_cmd)(hl_redis* c, vbyte* cmd) {
    if (!c || !c->ctx) return NULL;
    redisReply* r = (redisReply*)redisCommand(c->ctx, (const char*)cmd);
    if (!r) return NULL;

    hl_redis_reply* h = (hl_redis_reply*)hl_gc_alloc_finalizer(sizeof(hl_redis_reply));
    h->finalize = reply_handle_finalizer;
    h->r = r;
    h->owner = 1;
    return h;
}

static bool append_command_argv_len(hl_redis* c, int argc, const char** argv, const size_t* lens) {
    if (!c || !c->ctx) return false;
    return redisAppendCommandArgv(c->ctx, argc, argv, lens) == REDIS_OK;
}

static bool append_command_argv(hl_redis* c, int argc, const char** argv) {
    size_t lens[4];
    int i;

    for (i = 0; i < argc; ++i) {
        lens[i] = strlen(argv[i]);
    }

    return append_command_argv_len(c, argc, argv, lens);
}

HL_PRIM bool HL_NAME(redis_set_bytes)(hl_redis* c, vbyte* key, vbyte* value, int value_len) {
    const char* argv[3];
    size_t lens[3];
    redisReply* r;
    int ok;

    if (!c || !c->ctx) return false;

    argv[0] = "SET";
    argv[1] = (const char*)key;
    argv[2] = (const char*)value;

    lens[0] = 3;
    lens[1] = strlen(argv[1]);
    lens[2] = (size_t)value_len;

    r = (redisReply*)redisCommandArgv(c->ctx, 3, argv, lens);
    if (!r) return false;

    ok = (r->type == REDIS_REPLY_STATUS);
    freeReplyObject(r);
    return ok;
}

HL_PRIM hl_redis_reply* HL_NAME(redis_hget_bytes)(hl_redis* c, vbyte* key, vbyte* field) {
    const char* argv[3];
    size_t lens[3];
    redisReply* r;
    hl_redis_reply* h;

    if (!c || !c->ctx) return NULL;

    argv[0] = "HGET";
    argv[1] = (const char*)key;
    argv[2] = (const char*)field;

    lens[0] = 4;
    lens[1] = strlen(argv[1]);
    lens[2] = strlen(argv[2]);

    r = (redisReply*)redisCommandArgv(c->ctx, 3, argv, lens);
    if (!r) return NULL;

    h = (hl_redis_reply*)hl_gc_alloc_finalizer(sizeof(hl_redis_reply));
    h->finalize = reply_handle_finalizer;
    h->r = r;
    h->owner = 1;
    return h;
}

HL_PRIM bool HL_NAME(redis_append_hset)(hl_redis* c, vbyte* key, vbyte* field, vbyte* value) {
    const char* argv[4];
    argv[0] = "HSET";
    argv[1] = (const char*)key;
    argv[2] = (const char*)field;
    argv[3] = (const char*)value;
    return append_command_argv(c, 4, argv);
}

HL_PRIM bool HL_NAME(redis_append_hset_bytes)(hl_redis* c, vbyte* key, vbyte* field, vbyte* value, int value_len) {
    const char* argv[4];
    size_t lens[4];

    argv[0] = "HSET";
    argv[1] = (const char*)key;
    argv[2] = (const char*)field;
    argv[3] = (const char*)value;

    lens[0] = 4;
    lens[1] = strlen(argv[1]);
    lens[2] = strlen(argv[2]);
    lens[3] = (size_t)value_len;

    return append_command_argv_len(c, 4, argv, lens);
}

HL_PRIM bool HL_NAME(redis_append_set_bytes)(hl_redis* c, vbyte* key, vbyte* value, int value_len) {
    const char* argv[3];
    size_t lens[3];

    argv[0] = "SET";
    argv[1] = (const char*)key;
    argv[2] = (const char*)value;

    lens[0] = 3;
    lens[1] = strlen(argv[1]);
    lens[2] = (size_t)value_len;

    return append_command_argv_len(c, 3, argv, lens);
}

HL_PRIM bool HL_NAME(redis_append_expire)(hl_redis* c, vbyte* key, int ttl_seconds) {
    char ttl_buf[32];
    const char* argv[3];

    snprintf(ttl_buf, sizeof(ttl_buf), "%d", ttl_seconds);
    argv[0] = "EXPIRE";
    argv[1] = (const char*)key;
    argv[2] = ttl_buf;
    return append_command_argv(c, 3, argv);
}

HL_PRIM bool HL_NAME(redis_append_sadd)(hl_redis* c, vbyte* key, vbyte* value) {
    const char* argv[3];
    argv[0] = "SADD";
    argv[1] = (const char*)key;
    argv[2] = (const char*)value;
    return append_command_argv(c, 3, argv);
}

HL_PRIM bool HL_NAME(redis_append_srem)(hl_redis* c, vbyte* key, vbyte* value) {
    const char* argv[3];
    argv[0] = "SREM";
    argv[1] = (const char*)key;
    argv[2] = (const char*)value;
    return append_command_argv(c, 3, argv);
}

HL_PRIM bool HL_NAME(redis_append_del)(hl_redis* c, vbyte* key) {
    const char* argv[2];
    argv[0] = "DEL";
    argv[1] = (const char*)key;
    return append_command_argv(c, 2, argv);
}

HL_PRIM bool HL_NAME(redis_subscribe)(hl_redis* c, vbyte* channel) {
    redisReply* r;
    const char* argv[2];
    size_t lens[2];

    if (!c || !c->ctx) return false;

    argv[0] = "SUBSCRIBE";
    lens[0] = 9;
    argv[1] = (const char*)channel;
    lens[1] = strlen((const char*)channel);

    r = (redisReply*)redisCommandArgv(c->ctx, 2, argv, lens);
    if (!r) return false;

    freeReplyObject(r);
    return true;
}

HL_PRIM bool HL_NAME(redis_unsubscribe)(hl_redis* c, vbyte* channel) {
    redisReply* r;
    const char* argv[2];
    size_t lens[2];

    if (!c || !c->ctx) return false;

    argv[0] = "UNSUBSCRIBE";
    lens[0] = 11;
    argv[1] = (const char*)channel;
    lens[1] = strlen((const char*)channel);

    r = (redisReply*)redisCommandArgv(c->ctx, 2, argv, lens);
    if (!r) return false;

    freeReplyObject(r);
    return true;
}

HL_PRIM int HL_NAME(redis_publish)(hl_redis* c, vbyte* channel, vbyte* message) {
    redisReply* r;
    int delivered;
    const char* argv[3];
    size_t lens[3];

    if (!c || !c->ctx) return -1;

    argv[0] = "PUBLISH";
    lens[0] = 7;
    argv[1] = (const char*)channel;
    lens[1] = strlen((const char*)channel);
    argv[2] = (const char*)message;
    lens[2] = strlen((const char*)message);

    r = (redisReply*)redisCommandArgv(c->ctx, 3, argv, lens);
    if (!r) return -1;
    if (r->type != REDIS_REPLY_INTEGER) {
        freeReplyObject(r);
        return -1;
    }

    delivered = (int)r->integer;
    freeReplyObject(r);
    return delivered;
}

HL_PRIM hl_redis_reply* HL_NAME(redis_get_reply)(hl_redis* c) {
    redisReply* r;
    void* raw = NULL;

    if (!c || !c->ctx) return NULL;
    if (redisGetReply(c->ctx, &raw) != REDIS_OK) return NULL;

    r = (redisReply*)raw;
    if (!r) return NULL;

    hl_redis_reply* h = (hl_redis_reply*)hl_gc_alloc_finalizer(sizeof(hl_redis_reply));
    h->finalize = reply_handle_finalizer;
    h->r = r;
    h->owner = 1;
    return h;
}

HL_PRIM int HL_NAME(redis_reply_type)(hl_redis_reply* r) {
    if (!r || !r->r) return -1;
    return r->r->type;
}

HL_PRIM vbyte* HL_NAME(redis_reply_string)(hl_redis_reply* r) {
    if (!r || !r->r) return NULL;
    if (!r->r->str) return NULL;

    int len = r->r->len;
    vbyte* out = hl_copy_bytes((vbyte*)r->r->str, len);
    return out;
}

HL_PRIM int HL_NAME(redis_reply_len)(hl_redis_reply* r) {
    if (!r || !r->r) return 0;
    switch (r->r->type) {
        case REDIS_REPLY_STRING:
        case REDIS_REPLY_STATUS:
        case REDIS_REPLY_ERROR:
            return r->r->len;
        case REDIS_REPLY_ARRAY:
            return (int)r->r->elements;
        default:
            return 0;
    }
}

HL_PRIM int HL_NAME(redis_reply_int)(hl_redis_reply* r) {
    if (!r || !r->r) return 0;
    return (int)r->r->integer;
}

HL_PRIM hl_redis_reply* HL_NAME(redis_reply_at)(hl_redis_reply* r, int idx) {
    if (!r || !r->r) return NULL;
    if (r->r->type != REDIS_REPLY_ARRAY) return NULL;
    if (idx < 0 || idx >= (int)r->r->elements) return NULL;

    hl_redis_reply* h = (hl_redis_reply*)hl_gc_alloc_finalizer(sizeof(hl_redis_reply));
    h->finalize = NULL;
    h->r = r->r->element[idx];
    h->owner = 0;
    return h;
}

HL_PRIM void HL_NAME(redis_reply_free)(hl_redis_reply* r) {
    if (!r || !r->r) return;
    if (r->owner) {
        freeReplyObject(r->r);
    }
    r->r = NULL;
}

DEFINE_PRIM(_REDIS,       redis_connect, _BYTES _I32);
DEFINE_PRIM(_BOOL,        redis_auth, _REDIS _BYTES);
DEFINE_PRIM(_BOOL,        redis_select, _REDIS _I32);
DEFINE_PRIM(_VOID,        redis_close, _REDIS);

DEFINE_PRIM(_REDIS_REPLY, redis_cmd, _REDIS _BYTES);
DEFINE_PRIM(_BOOL,        redis_set_bytes, _REDIS _BYTES _BYTES _I32);
DEFINE_PRIM(_REDIS_REPLY, redis_hget_bytes, _REDIS _BYTES _BYTES);
DEFINE_PRIM(_BOOL,        redis_append_hset, _REDIS _BYTES _BYTES _BYTES);
DEFINE_PRIM(_BOOL,        redis_append_hset_bytes, _REDIS _BYTES _BYTES _BYTES _I32);
DEFINE_PRIM(_BOOL,        redis_append_set_bytes, _REDIS _BYTES _BYTES _I32);
DEFINE_PRIM(_BOOL,        redis_append_expire, _REDIS _BYTES _I32);
DEFINE_PRIM(_BOOL,        redis_append_sadd, _REDIS _BYTES _BYTES);
DEFINE_PRIM(_BOOL,        redis_append_srem, _REDIS _BYTES _BYTES);
DEFINE_PRIM(_BOOL,        redis_append_del, _REDIS _BYTES);
DEFINE_PRIM(_BOOL,        redis_subscribe, _REDIS _BYTES);
DEFINE_PRIM(_BOOL,        redis_unsubscribe, _REDIS _BYTES);
DEFINE_PRIM(_I32,         redis_publish, _REDIS _BYTES _BYTES);
DEFINE_PRIM(_REDIS_REPLY, redis_get_reply, _REDIS);

DEFINE_PRIM(_I32,         redis_reply_type, _REDIS_REPLY);
DEFINE_PRIM(_BYTES,       redis_reply_string, _REDIS_REPLY);
DEFINE_PRIM(_I32,         redis_reply_len, _REDIS_REPLY);
DEFINE_PRIM(_I32,         redis_reply_int, _REDIS_REPLY);
DEFINE_PRIM(_REDIS_REPLY, redis_reply_at, _REDIS_REPLY _I32);
DEFINE_PRIM(_VOID,        redis_reply_free, _REDIS_REPLY);
