package lime.graphics.console;


@:enum abstract RasterizerState(Int) {

	var CULLNONE_WIREFRAME  = 0;
	var CULLCW_WIREFRAME    = 1;
	var CULLCCW_WIREFRAME   = 2;
	var CULLNONE_SOLID      = 3;
	var CULLCW_SOLID        = 4;
	var CULLCCW_SOLID       = 5;

}


@:enum abstract DepthStencilState(Int) {

	var DEPTHTESTOFF_DEPTHWRITEOFF_STENCILOFF           = 0;
	var DEPTHTESTON_DEPTHWRITEON_DEPTHLESS_STENCILOFF   = 1;
	var DEPTHTESTON_DEPTHWRITEOFF_DEPTHLESS_STENCILOFF  = 2;
	var DEPTHTESTOFF_DEPTHWRITEON_DEPTHLESS_STENCILOFF  = 3;
	var DEPTHTESTON_DEPTHWRITEON_DEPTHALWAYS_STENCILOFF = 4;

}


@:enum abstract BlendState(Int) {

	var NONE_A											= 0;
	var NONE_RGB                                        = 1;
	var NONE_RGBA                                       = 2;
	var SRCALPHA_INVSRCALPHA_ONE_ZERO_RGB               = 3;
	var SRCALPHA_INVSRCALPHA_ONE_ZERO_RGBA              = 4;
	var SRCALPHA_INVSRCALPHA_SRCALPHA_INVSRCALPHA_RGBA  = 5;
	var SRCALPHA_INVSRCALPHA_INVDESTALPHA_ONE_RGBA      = 6;
	var ZERO_INVSRCCOLOR_ONE_ZERO_RGBA                  = 7;
	var ZERO_SRCCOLOR_ONE_ZERO_RGBA                     = 8;
	var SRCALPHA_ONE_ONE_ZERO_RGBA                      = 9;
	var SRCALPHA_ONE_ONE_ONE_RGBA                       = 10;
	var DESTCOLOR_SRCCOLOR_ONE_ZERO_RGBA                = 11;
	var ONE_ONE_ONE_ZERO_RGBA                           = 12;
	var ONE_ONE_ONE_ONE_RGBA                            = 13;
	var ONE_ZERO_ONE_ZERO_RGBA                          = 14;
	var ZERO_ONE_ZERO_ONE                               = 15;

}
