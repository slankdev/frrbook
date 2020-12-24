
## Debug log misc

```
#define C_RED "\x1b[31m"
#define C_GRN "\x1b[32m"
#define C_YEL "\x1b[33m"
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
