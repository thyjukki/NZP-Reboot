	.set noreorder

#include "pspstub.s"

	STUB_START "VramExt",0x40090000,0x00010005
	STUB_FUNC  0xA5853E1E,VramSetSize
	STUB_END