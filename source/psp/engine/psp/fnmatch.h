#define	FNM_NOMATCH	(1)	/* Match failed. */
#define	FNM_NOSYS	(2)	/* Function not implemented. */

#define	FNM_NOESCAPE	(0x01)	/* Disable backslash escaping. */
#define	FNM_PATHNAME	(0x02)	/* Slash must be matched by slash. */
#define	FNM_PERIOD	(0x04)	/* Period must be matched by period. */
#define	FNM_CASEFOLD	(0x08)	/* Pattern is matched case-insensitive */
#define	FNM_LEADING_DIR	(0x10)	/* Ignore /<tail> after Imatch. */

int fnmatch(const char *pattern, const char *string, int flags);
