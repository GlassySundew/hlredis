#define HL_NAME(n) redis_##n

#include <hl.h>
#include <stdlib.h>
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

HL_PRIM int HL_NAME(redis_reply_type)(hl_redis_reply* r) {
    if (!r || !r->r) return -1;
    return r->r->type;
}

HL_PRIM vbyte* HL_NAME(redis_reply_string)(hl_redis_reply* r) {
    if (!r || !r->r) return NULL;
    if (!r->r->str) return NULL;

    int len = (int)strlen(r->r->str);
    vbyte* out = hl_copy_bytes((vbyte*)r->r->str, len);
    return out;
}

HL_PRIM int HL_NAME(redis_reply_len)(hl_redis_reply* r) {
    if (!r || !r->r) return 0;
    return r->r->elements;
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

DEFINE_PRIM(_I32,         redis_reply_type, _REDIS_REPLY);
DEFINE_PRIM(_BYTES,       redis_reply_string, _REDIS_REPLY);
DEFINE_PRIM(_I32,         redis_reply_len, _REDIS_REPLY);
DEFINE_PRIM(_I32,         redis_reply_int, _REDIS_REPLY);
DEFINE_PRIM(_REDIS_REPLY, redis_reply_at, _REDIS_REPLY _I32);
DEFINE_PRIM(_VOID,        redis_reply_free, _REDIS_REPLY);
