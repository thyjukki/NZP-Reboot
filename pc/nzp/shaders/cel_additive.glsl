!!permu FRAMEBLEND
!!permu SKELETAL
!!permu FOG

varying vec2 tc;
varying float va;

#ifdef VERTEX_SHADER
#include "sys/skeletal.h"
attribute vec2 v_texcoord;
uniform vec3 e_eyepos;

void main ()
{
	vec3 n;
	gl_Position = skeletaltransform_n(n);
	va = dot(n, vec3(0,0,10));
	tc = v_texcoord;
}
#endif


#ifdef FRAGMENT_SHADER
#include "sys/fog.h"
uniform sampler2D s_t0;

uniform vec4 e_colourident;
void main ()
{
	vec4 col;
	col = texture2D(s_t0, tc);
	col.rgb -= 1 - e_colourident.a;
	col.a = (col.r + col.g + col.b)/3;
	//col.a -= 1 - e_colourident.a;
	if(col.a > 0.1)
		col.a = 1;
	else
		col.a = 0;
	col.rgb = 0.8*normalize(col.rgb) + 0.7*col.rgb;
	//col.rgb = vec3(0.5,0.5,0.5);
	//col.rgb = floor(col.rgb + 0.5);
	gl_FragColor = fog4(col);
}
#endif