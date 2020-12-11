
#define	FNM_NOMATCH	(1)	/* Match failed. */
#define	FNM_NOSYS	(2)	/* Function not implemented. */

#define	FNM_NOESCAPE	(0x01)	/* Disable backslash escaping. */
#define	FNM_PATHNAME	(0x02)	/* Slash must be matched by slash. */
#define	FNM_PERIOD	(0x04)	/* Period must be matched by period. */
#define	FNM_CASEFOLD	(0x08)	/* Pattern is matched case-insensitive */
#define	FNM_LEADING_DIR	(0x10)	/* Ignore /<tail> after Imatch. */

#include <ctype.h>
#include <string.h>
#include "fnmatch.h"

#define	EOS	'\0'

static const char *rangematch(const char *, int, int);

static inline int
foldcase(int ch, int flags)
{

	if ((flags & FNM_CASEFOLD) != 0 && isupper(ch))
		return (tolower(ch));
	return (ch);
}

#define	FOLDCASE(ch, flags)	foldcase((unsigned char)(ch), (flags))

int fnmatch(const char *pattern, const char *string, int flags)
{
	const char *stringstart;
	char c, test;

	for (stringstart = string;;)
		switch (c = FOLDCASE(*pattern++, flags)) {
		case EOS:
			if ((flags & FNM_LEADING_DIR) && *string == '/')
				return (0);
			return (*string == EOS ? 0 : FNM_NOMATCH);
		case '?':
			if (*string == EOS)
				return (FNM_NOMATCH);
			if (*string == '/' && (flags & FNM_PATHNAME))
				return (FNM_NOMATCH);
			if (*string == '.' && (flags & FNM_PERIOD) &&
			    (string == stringstart ||
			    ((flags & FNM_PATHNAME) && *(string - 1) == '/')))
				return (FNM_NOMATCH);
			++string;
			break;
		case '*':
			c = FOLDCASE(*pattern, flags);
			/* Collapse multiple stars. */
			while (c == '*')
				c = FOLDCASE(*++pattern, flags);

			if (*string == '.' && (flags & FNM_PERIOD) &&
			    (string == stringstart ||
			    ((flags & FNM_PATHNAME) && *(string - 1) == '/')))
				return (FNM_NOMATCH);

			/* Optimize for pattern with * at end or before /. */
			if (c == EOS) {
				if (flags & FNM_PATHNAME)
					return ((flags & FNM_LEADING_DIR) ||
					    strchr(string, '/') == NULL ?
					    0 : FNM_NOMATCH);
				else
					return (0);
			} else if (c == '/' && flags & FNM_PATHNAME) {
				if ((string = strchr(string, '/')) == NULL)
					return (FNM_NOMATCH);
				break;
			}

			/* General case, use recursion. */
			while ((test = FOLDCASE(*string, flags)) != EOS) {
				if (!fnmatch(pattern, string,
					     flags & ~FNM_PERIOD))
					return (0);
				if (test == '/' && flags & FNM_PATHNAME)
					break;
				++string;
			}
			return (FNM_NOMATCH);
		case '[':
			if (*string == EOS)
				return (FNM_NOMATCH);
			if (*string == '/' && flags & FNM_PATHNAME)
				return (FNM_NOMATCH);
			if ((pattern =
			    rangematch(pattern, FOLDCASE(*string, flags),
				       flags)) == NULL)
				return (FNM_NOMATCH);
			++string;
			break;
		case '\\':
			if (!(flags & FNM_NOESCAPE)) {
				if ((c = FOLDCASE(*pattern++, flags)) == EOS) {
					c = '\\';
					--pattern;
				}
			}
			/* FALLTHROUGH */
		default:
			if (c != FOLDCASE(*string++, flags))
				return (FNM_NOMATCH);
			break;
		}
	/* NOTREACHED */
}

static const char * rangematch(const char *pattern, int test, int flags)
{
	int negate, ok;
	char c, c2;

	if ((negate = (*pattern == '!' || *pattern == '^')) != 0)
		++pattern;

	for (ok = 0; (c = FOLDCASE(*pattern++, flags)) != ']';) {
		if (c == '\\' && !(flags & FNM_NOESCAPE))
			c = FOLDCASE(*pattern++, flags);
		if (c == EOS)
			return (NULL);
		if (*pattern == '-'
		    && (c2 = FOLDCASE(*(pattern+1), flags)) != EOS &&
		        c2 != ']') {
			pattern += 2;
			if (c2 == '\\' && !(flags & FNM_NOESCAPE))
				c2 = FOLDCASE(*pattern++, flags);
			if (c2 == EOS)
				return (NULL);
			if (c <= test && test <= c2)
				ok = 1;
		} else if (c == test)
			ok = 1;
	}
	return (ok == negate ? NULL : pattern);
}

