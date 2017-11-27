
ifeq ("$(ARCHS)","normal")
	ARCHS = armv6 armv7 i386
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
   CONFIG := Debug
else
   DEBUG :=
   CONFIG := Release
endif

HAXE_OS := $(PLATFORM_NAME)
ifeq ("$(HAXE_OS)","iphonesimulator")
   HAXE_OS := iphonesim
endif
CONFIG := $(CONFIG)-$(HAXE_OS)

debug_print:
	@echo "Make $(HAXE_BUILDS)"

LIB_BASE := build/$(CONFIG)/::CPP_LIBPREFIX::ApplicationMain$(DEBUG)
LIB_DEST := $(DEBUG)/libApplicationMain.a

build-haxe-i386:
	@echo "Haxe simulator build: $(CONFIG)"
	haxe Build.hxml -D simulator -cpp build/$(CONFIG) $(DEBUG)
	cd build/$(CONFIG); ::HAXELIB_PATH:: export HXCPP_NO_COLOR=1; haxelib run ::CPP_BUILD_LIBRARY:: Build.xml $(DEBUG) -options Options.txt
	cp build/$(CONFIG)/::CPP_LIBPREFIX::ApplicationMain$(DEBUG).iphonesim.a ../lib/i386$(LIB_DEST)
	touch ../Classes/Main.mm

build-haxe-x86_64:
	@echo "Haxe simulator build: $(CONFIG)-64"
	haxe Build.hxml -D simulator -D HXCPP_M64 -cpp build/$(CONFIG)-64 $(DEBUG)
	cd build/$(CONFIG)-64; ::HAXELIB_PATH:: export HXCPP_NO_COLOR=1; haxelib run ::CPP_BUILD_LIBRARY:: Build.xml $(DEBUG) -options Options.txt
	cp build/$(CONFIG)-64/::CPP_LIBPREFIX::ApplicationMain$(DEBUG).iphonesim-64.a ../lib/x86_64$(LIB_DEST)
	touch ../Classes/Main.mm

build-haxe-armv6:
	@echo "Haxe device build: $(CONFIG)"
	haxe Build.hxml -D HXCPP_ARMV6 -cpp build/$(CONFIG) $(DEBUG)
	cd build/$(CONFIG); ::HAXELIB_PATH:: export HXCPP_NO_COLOR=1; haxelib run ::CPP_BUILD_LIBRARY:: Build.xml $(DEBUG) -options Options.txt
	cp build/$(CONFIG)/::CPP_LIBPREFIX::ApplicationMain$(DEBUG).iphoneos.a ../lib/armv6$(LIB_DEST)
	touch ../Classes/Main.mm

build-haxe-armv7:
	@echo "Haxe device build: $(CONFIG)-v7"
	haxe Build.hxml -D HXCPP_ARMV7 -cpp build/$(CONFIG)-v7 $(DEBUG)
	cd build/$(CONFIG)-v7; ::HAXELIB_PATH:: export HXCPP_NO_COLOR=1; haxelib run ::CPP_BUILD_LIBRARY:: Build.xml $(DEBUG) -options Options.txt
	cp build/$(CONFIG)-v7/::CPP_LIBPREFIX::ApplicationMain$(DEBUG).iphoneos-v7.a ../lib/armv7$(LIB_DEST)
	touch ../Classes/Main.mm

build-haxe-arm64:
	@echo "Haxe device build: $(CONFIG)-64"
	haxe Build.hxml -D HXCPP_ARM64 -cpp build/$(CONFIG)-64 $(DEBUG)
	cd build/$(CONFIG)-64; ::HAXELIB_PATH:: export HXCPP_NO_COLOR=1; haxelib run ::CPP_BUILD_LIBRARY:: Build.xml $(DEBUG) -options Options.txt
	cp build/$(CONFIG)-64/::CPP_LIBPREFIX::ApplicationMain$(DEBUG).iphoneos-64.a ../lib/arm64$(LIB_DEST)
	touch ../Classes/Main.mm

clean:
	rm -rf build
