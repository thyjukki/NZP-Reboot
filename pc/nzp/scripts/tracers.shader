tracers/mg
{
	cull disable
	{
		map $nearest:models/weapons/mg/tracer.tga
		rgbGen identity
		alphaGen vertex
		blendFunc GL_SRC_ALPHA GL_ONE
	}
}