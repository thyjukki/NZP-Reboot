textures/dev/white
{
	{
		map $nearest:textures/dev/white.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}

textures/dev/gray
{
	{
		map $nearest:textures/dev/gray.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}

textures/dev/graydark
{
	{
		map $nearest:textures/dev/graydark.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}

textures/dev/black
{
	{
		map $nearest:textures/dev/black.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}

textures/dev/green
{
	{
		map $nearest:textures/dev/green.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}

textures/dev/blue
{
	{
		map $nearest:textures/dev/blue.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}

textures/dev/brown
{
	{
		map $nearest:textures/dev/brown.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}
textures/dev/beige
{
	{
		map $nearest:textures/dev/beige.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}

textures/dev/orange
{
	{
		map $nearest:textures/dev/orange.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}

textures/dev/red
{
	{
		map $nearest:textures/dev/red.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}

textures/dev/purple
{
	{
		map $nearest:textures/dev/purple.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}

textures/dev/yellow
{
	{
		map $nearest:textures/dev/yellow.tga
		rgbGen identity
	}
	{
		map $lightmap
		blendFunc GL_DST_COLOR GL_ZERO
		rgbGen identity
	}
}

textures/dev/test_sky
{
	qer_editorimage textures/dev/edsky.tga

	q3map_globaltexture
	q3map_lightsubdivide 256
	q3map_surfaceLight 120
	q3map_sun 0.7 0.6 0.8 550 60 45
	
	surfaceparm sky
	surfaceparm noimpact
	surfaceparm nolightmap
	surfaceparm nomarks
	skyparms textures/tropical/sky - -
}