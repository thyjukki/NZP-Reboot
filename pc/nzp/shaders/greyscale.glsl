!!ver 130
//   author: lezard //https://blog.sovapps.com/author/lezard/
//   https://blog.sovapps.com/play-with-shaders-black-and-white-part-1/
#ifdef VERTEX_SHADER
attribute vec2 v_texcoord;
varying vec2 v_edge;
void main ()
{
   gl_Position = ftetransform();
   v_edge = v_texcoord.xy;
}
#endif
#ifdef FRAGMENT_SHADER
uniform sampler2D s_t0;
varying vec2 v_edge;
varying vec3 graycol;
uniform vec4 tint = vec4(1,1,1,1);

void main ()
{

   gl_FragColor = texture2D(s_t0, v_edge.xy);
   vec4 normalColor = texture2D(s_t0, v_edge.xy);
    float gray = 0.299*normalColor.r + 0.587*normalColor.g + 0.114*normalColor.b;
    gl_FragColor = vec4(gray, gray, gray, normalColor.a);
}
#endif
