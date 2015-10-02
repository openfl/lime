
ifeq ("$(ARCHS)","normal")
	ARCHS = arm64 i386
endif

HAXE_BUILDS := $(ARCHS:%=build-haxe-%)

ifeq ("$(ACTION)","clean")
default: clean
else
default: $(HAXE_BUILDS)
endif

ifeq ("$(CONFIGURATION)","Debug")
   BUILD_STYLE := Debug
endif

default: debug_print

ifeq ("$(BUILD_STYLE)","Debug")
   DEBUG := -debug
   DEF_DEBUG := -Ddebug
   CONFIG := Debug
else
   DEBUG :=
   DEF_DEBUG :=
   CONFIG := Release
endif

ifeq ("$(CLANG_ENABLE_OBJC_ARC)", "YES")
   HXCPP_CLANG := -DHXCPP_CLANG -DOBJC_ARC
else
   HXCPP_CLANG := 
endif

HAXE_OS := $(PLATFORM_NAME)
ifeq ("$(HAXE_OS)","appletvsimulator")
   HAXE_OS := appletvsim
endif
CONFIG := $(CONFIG)-$(HAXE_OS)

debug_print:
	@echo "Make $(HAXE_BUILDS)"

LIB_BASE := build/$(CONFIG)/::CPP_LIBPREFIX::ApplicationMain$(DEBUG)
LIB_DEST := $(DEBUG)/libApplicationMain.a

build-haxe-i386:
	@echo "Haxe simulator build: $(CONFIG)"
	haxe Build.hxml -D simulator -cpp build/$(CONFIG) $(DEBUG)
	cd build/$(CONFIG); export HXCPP_NO_COLOR=1; haxelib run ::CPP_BUILD_LIBRARY:: Build.xml -Dtvos -Dsimulator -DHXCPP_CPP11 $(DEF_DEBUG) $(HXCPP_CLANG) `cat Options.txt | while read LINE; do printf " -D$$LINE"; done`
	cp build/$(CONFIG)/::CPP_LIBPREFIX::ApplicationMain$(DEBUG).appletvsim.a ../lib/i386$(LIB_DEST)
	touch ../Classes/Main.mm

build-haxe-x86_64:
	@echo "Haxe simulator build: $(CONFIG)-64"
	haxe Build.hxml -D simulator -D HXCPP_M64 -cpp build/$(CONFIG)-64 $(DEBUG)
	cd build/$(CONFIG)-64; export HXCPP_NO_COLOR=1; haxelib run ::CPP_BUILD_LIBRARY:: Build.xml -Dtvos -Dsimulator -DHXCPP_M64 -DHXCPP_CPP11 $(DEF_DEBUG) $(HXCPP_CLANG) `cat Options.txt | while read LINE; do printf " -D$$LINE"; done`
	cp build/$(CONFIG)-64/::CPP_LIBPREFIX::ApplicationMain$(DEBUG).appletvsim-64.a ../lib/x86_64$(LIB_DEST)
	touch ../Classes/Main.mm

build-haxe-arm64:
	@echo "Haxe device build: $(CONFIG)-64"
	haxe Build.hxml -D HXCPP_ARM64 -cpp build/$(CONFIG)-64 $(DEBUG)
	cd build/$(CONFIG)-64; export HXCPP_NO_COLOR=1; haxelib run ::CPP_BUILD_LIBRARY:: Build.xml -Dtvos -DHXCPP_ARM64 -DHXCPP_CPP11 $(DEF_DEBUG) $(HXCPP_CLANG) `cat Options.txt | while read LINE; do printf " -D$$LINE"; done`
	cp build/$(CONFIG)-64/::CPP_LIBPREFIX::ApplicationMain$(DEBUG).appletvos-64.a ../lib/arm64$(LIB_DEST)
	touch ../Classes/Main.mm

clean:
	rm -rf build
