#ifndef RANDOM_H
#define RANDOM_H

// the random number seeding is automatic
#define MAX_RANDOM_RANGE 0x7FFFFFFFUL

// restarts random generator 
// setting lSeed to 0 causes the current time to be used as the seed
// random number generator will automatically seed itself on first use with current time if this is not called
void SeedRandomNumberGenerator(long lSeed = 0);

// returns a random integer of range [low, high]
long RandomLong( long lLow, long lHigh );

// returns a random float of range [low, high)
float RandomFloat( float flLow, float flHigh );

#endif // RANDOM_H
