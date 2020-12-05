
// Copied from newlib as the current newlib did not include it

#include <stdio.h>
#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/socket.h>
#include <pspkerneltypes.h>
#include <pspnet_resolver.h>
#include <string.h>
#include <psputility.h>

#define MAX_NAME 512

#ifdef F_h_errno
int h_errno = NETDB_SUCCESS;
#endif

struct hostent *gethostbyaddr(const void *addr, int len, int type)
{
	static struct hostent ent;
    static char * aliases[1] = { NULL };
	char buf[1024];
	static char sname[MAX_NAME] = "";
	static struct in_addr saddr = { 0 };
	static char *addrlist[2] = { (char *) &saddr, NULL };
	int rid;
	int err;

	if((len != sizeof(struct in_addr)) || (type != AF_INET) || (addr == NULL))
	{
		h_errno = HOST_NOT_FOUND;
		return NULL;
	}

	memcpy(&saddr, addr, len);

	if(sceNetResolverCreate(&rid, buf, sizeof(buf)) < 0)
	{
		h_errno = NO_RECOVERY;
		return NULL;
	}

	err = sceNetResolverStartAtoN(rid, &saddr, sname, sizeof(sname), 2, 3);
	sceNetResolverStop(rid);
	sceNetResolverDelete(rid);
	if(err < 0)
	{
		h_errno = HOST_NOT_FOUND;
		return NULL;
	}

	ent.h_name = sname;
	ent.h_aliases = aliases;
	ent.h_addrtype = AF_INET;
	ent.h_length = sizeof(struct in_addr);
	ent.h_addr_list = addrlist;
	ent.h_addr = (char *) &saddr;

	return &ent;
}

struct hostent *gethostbyname(const char *name)
{
	static struct hostent ent;
	char buf[1024];
	static char sname[MAX_NAME] = "";
	static struct in_addr saddr = { 0 };
	static char *addrlist[2] = { (char *) &saddr, NULL };
	int rid;

	if(sceNetInetInetAton(name, &saddr) == 0)
	{
		int err;

		if(sceNetResolverCreate(&rid, buf, sizeof(buf)) < 0)
		{
			h_errno = NO_RECOVERY;
			return NULL;
		}

		err = sceNetResolverStartNtoA(rid, name, &saddr, 2, 3);
		sceNetResolverDelete(rid);
		if(err < 0)
		{
			h_errno = HOST_NOT_FOUND;
			return NULL;
		}

	}

	snprintf(sname, MAX_NAME, "%s", name);
	ent.h_name = sname;
	ent.h_aliases = 0;
	ent.h_addrtype = AF_INET;
	ent.h_length = sizeof(struct in_addr);
	ent.h_addr_list = addrlist;
	ent.h_addr = (char *) &saddr;

	return &ent;
}

int gethostname(char *name, int namelen)
{
    memset(name, 0, namelen);
    if(sceUtilityGetSystemParamString(PSP_SYSTEMPARAM_ID_STRING_NICKNAME,
										name, namelen) == PSP_SYSTEMPARAM_RETVAL_FAIL)
	{
		strcpy(name, "UNNAMED");
		return -1;
    }

	return 1;
}
