ARG HAXE_VERSION=3.4.3
ARG UBUNTU_VERSION=16.04

FROM haxe:${HAXE_VERSION} as haxe

FROM ubuntu:${UBUNTU_VERSION}
RUN apt-get update -yqq && apt-get install -yq \
	libgl1-mesa-dev \
	libglu1-mesa-dev \
	g++ \
	g++-multilib \
	gcc-multilib \
	libasound2-dev \
	libx11-dev \
	libxext-dev \
	libxi-dev \
	libxrandr-dev \
	libxinerama-dev \
	libgc1c2 \
	git \
	vim

COPY --from=haxe /usr/local/lib/haxe/ /usr/local/lib/haxe/
COPY --from=haxe /usr/local/bin/haxe* /usr/local/bin/
COPY --from=haxe /usr/local/bin/haxelib /usr/local/bin/
COPY --from=haxe /usr/local/lib/neko/ /usr/local/lib/neko/
COPY --from=haxe /usr/local/lib/libneko* /usr/local/lib/
COPY --from=haxe /usr/local/lib/libneko* /usr/lib/
COPY --from=haxe /usr/local/bin/neko* /usr/local/bin/

# TODO: Add Android SDK, Emscripten SDK, etc

RUN haxelib setup /usr/lib/haxe/lib/
RUN haxelib install hxcpp
RUN haxelib git format https://github.com/jgranick/format
RUN haxelib install munit
RUN haxelib install hxp

COPY . /opt/lime/
COPY templates/bin/lime.sh /usr/local/bin/lime
RUN haxelib dev lime /opt/lime/
RUN lime rebuild linux
RUN lime rebuild tools

RUN rm -rf /opt/lime/project/obj

CMD [ "lime" ]