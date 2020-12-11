mg_ammo
{
	program shaders/mg_ammo.glsl
	{
		map $nearest:models/mg_ammo.png
	}	
}

muzzleflash
{
	cull disable
	//program shaders/cel_additive.glsl
	{
		map models/weapons/mg/matalt3.tga
		blendFunc GL_SRC_ALPHA GL_ONE
		rgbGen identity
		alphaGen entity
	}
}

bloodsplat
{
	cull disable
	program shaders/splat.glsl
	{
		map textures/blood2.tga
		rgbGen identity
		alphaGen entity
	}
}

bloodsplat2
{
	cull disable
	program shaders/splat2.glsl
	{
		map textures/blood2.tga
		blendFunc blend
		rgbGen vertex
		alphaGen vertex
	}
}

pistol
{
	bemode rtlight
	{
		program shaders/cel_rtlight.glsl
		{
			map $diffuse
			blendFunc add
		}
		{
			map $lightcubemap
		}
		{
			map $shadowmap
		}
	}
	//program shaders/celshade.glsl
	nomipmaps
	{
		map $nearest:models/weapons/pistol/pistol.tga
		rgbGen lightingDiffuse
		alphaGen entity
	}
}

mgtex
{
	bemode rtlight
	{
		program shaders/cel_rtlight.glsl

		{
			map $diffuse
			blendFunc add
		}
		{
			map $lightcubemap
		}
		{
			map $shadowmap
		}
	}
	//program shaders/celshade.glsl
	nomipmaps
	{
		map $nearest:models/weapons/mg/mgtex.tga
		rgbGen lightingDiffuse
		alphaGen entity
	}
}

outline
{
	cull back
	program shaders/outline.glsl
	{
	}
}

perse
{
	program shaders/celshade.glsl
	nomipmaps
	{
		map $nearest:models/perse.tga
		rgbGen lightingDiffuse
		alphaGen entity
	}
}