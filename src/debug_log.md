## Debug log misc

```cpp
#define C_RED "\x1b[31m"
#define C_GRN "\x1b[32m"
#define C_YEL "\x1b[33m"
#define C_BLU "\x1b[34m"
#define C_PPL "\x1b[35m"
#define C_CYN "\x1b[36m"
#define C_DEF "\x1b[39m"
#define C_BG_RED "\x1b[41m"
#define C_BG_DEF "\x1b[49m"

#define marker_debug() { \
    zlog_debug(C_YEL "%s:%d:%s()" C_DEF, __FILE__, __LINE__, __func__); \
  } while(0)

#define marker_debug_msg(fmt) { \
    char str[1000]; \
    snprintf(str, sizeof(str), fmt); \
    zlog_debug(C_YEL "%s:%d:%s() %s" C_DEF, __FILE__, __LINE__, __func__, str); \
  } while(0)

#define marker_debug_fmsg(fmt, ...) { \
    char str[1000]; \
    snprintf(str, sizeof(str), fmt, __VA_ARGS__); \
    zlog_debug(C_YEL "%s:%d:%s() %s" C_DEF, __FILE__, __LINE__, __func__, str); \
  } while(0)
  
```

## NB callback

```c
static inline void cli_show_dummy(struct vty *vty, const struct lyd_node *dnode,
				  bool show_defaults)
{
	char xpath[256];
	yang_dnode_get_path(dnode, xpath, sizeof(xpath));
	zlog_debug("Dummy nb cli_show (%s)", xpath);
}

static inline void cli_show_dummy_end(struct vty *vty, struct lyd_node *dnode)
{
	char xpath[256];
	yang_dnode_get_path(dnode, xpath, sizeof(xpath));
	zlog_debug("Dummy nb cli_show_end (%s)", xpath);
}

static inline int dummy_create(struct nb_cb_create_args *args)
{
	char xpath[256];
	yang_dnode_get_path(args->dnode, xpath, sizeof(xpath));
	zlog_debug("Dummy nb create (%s)", xpath);
	return 0;
}

static inline int dummy_modify(struct nb_cb_modify_args *args)
{
	char xpath[256];
	yang_dnode_get_path(args->dnode, xpath, sizeof(xpath));
	zlog_debug("Dummy nb modify (%s)", xpath);
	return 0;
}

static inline int dummy_destroy(struct nb_cb_destroy_args *args)
{
	char xpath[256];
	yang_dnode_get_path(args->dnode, xpath, sizeof(xpath));
	zlog_debug("Dummy nb destroy (%s)", xpath);
	return 0;
}

static inline const void *dummy_get_next(struct nb_cb_get_next_args *args)
{
	char xpath[256];
	// yang_dnode_get_path(args->dnode, xpath, sizeof(xpath));
	zlog_debug("Dummy nb get_next (%s)", xpath);
	return NULL;
}

static inline int dummy_get_keys(struct nb_cb_get_keys_args *args)
{
	char xpath[256];
	// yang_dnode_get_path(args->dnode, xpath, sizeof(xpath));
	zlog_debug("Dummy nb get_keys (%s)", xpath);
	return 0;
}

static inline const void *dummy_lookup_entry(struct nb_cb_lookup_entry_args *args)
{
	char xpath[256];
	// yang_dnode_get_path(args->dnode, xpath, sizeof(xpath));
	zlog_debug("Dummy nb lookup_entry (%s)", xpath);
	return NULL;
}

static inline int dummy_pre_validate(struct nb_cb_pre_validate_args *args)
{
	char xpath[256];
	yang_dnode_get_path(args->dnode, xpath, sizeof(xpath));
	zlog_debug("Dummy nb pre_validate (%s)", xpath);
	return 0;
}

static inline void dummy_apply_finish(struct nb_cb_apply_finish_args *args)
{
	char xpath[256];
	yang_dnode_get_path(args->dnode, xpath, sizeof(xpath));
	zlog_debug("Dummy nb apply_finish (%s)", xpath);
}

static inline struct yang_data *
dummy_get_elem(struct nb_cb_get_elem_args *args)
{
	zlog_debug("Dummy nb get_elem (%s)", args->xpath);
	return NULL;
}
```
