
#ifndef GETHOST
#define GETHOST

struct hostent *gethostbyaddr(const void *addr, int len, int type);
struct hostent *gethostbyname(const char *name);
int gethostname(char *name, int namelen);

#endif
