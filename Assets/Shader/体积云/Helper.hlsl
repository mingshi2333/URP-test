#ifndef __Cloud__
#define __Cloud__

#ifndef PI
#define PI 3.14159265359
#endif

float Beer(float density, float absorptivity = 1)
{
    return exp(-density * absorptivity);
}

float BeerPowder(float density, float absorptivity = 1)
{
    return 2.0 * exp(-density * absorptivity) * (1.0 - exp(-2.0 * density));
}

float HenyeyGreenstein(float angle, float g)
{
    float g2 = g * g;
    return(1.0 - g2) / (4.0 * PI * pow(1.0 + g2 - 2.0 * g * angle, 1.5));
}

#endif
