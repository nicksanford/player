MACOSX_DEPLOYMENT_TARGET ?= 14.0.0
CC = zig cc
PLATFORM ?= $(shell uname -s)-$(shell uname -m)
BIN_OUTPUT_PATH ?= bin/$(PLATFORM)
# RAYLIB_VERSION ?= 9b183e0c5e5786a8a92e34e6a8f941586c12c39d 
# CFLAGS ?= -Wall -Wextra -Wpedantic -Wnull-dereference -Wdouble-promotion  -Wshadow -Wunused -Wenum-conversion -Wuninitialized -Werror -Wno-unused-parameter -g -fdata-sections -ffunction-sections -fno-omit-frame-pointer -fsanitize-address-use-after-scope -fno-common -ggdb -fsanitize=address -fsanitize-address-use-after-scope  
CFLAGS ?= -Wall -Wextra -Wpedantic -Wnull-dereference -Wdouble-promotion  -Wshadow -Wunused -Wenum-conversion -Wuninitialized -Werror -Wno-unused-parameter -g -fdata-sections -ffunction-sections -fno-omit-frame-pointer -fno-common -ggdb 
RAYLIB_TARGET=build/lib/libraylib.a
FFMPEG_TARGET=build/lib/libavcodec.a
FFMPEG_LIBS=    libavformat \
                libavcodec  \
                libavutil   \
                libswscale  


SOURCE_OS ?= $(shell uname -s | tr '[:upper:]' '[:lower:]')
# NPROC ?= $(shell nproc)
# ifeq ($(SOURCE_OS),linux)
#     NPROC ?= $(shell nproc)
# else ifeq ($(SOURCE_OS),darwin)
#     NPROC ?= $(shell sysctl -n hw.ncpu)
# else
#     NPROC ?= 1
# endif

# ifeq ($(PLATFORM),Darwin-arm64)
# LDFLAGS += -framework CoreVideo -framework Cocoa -framework IOKit -framework GLUT -framework OpenGL
# else
# 	echo $(PLATFORM) not yet supported. Please edit Makefile
# 	exit 1
# endif
#
.PHONY: scribe clean clean-all

scribe: build $(RAYLIB_TARGET) $(FFMPEG_TARGET) scribe.c 
scribe: 
	$(eval LDFLAGS += -Ibuild/include -Lbuild/lib -lraylib)
	$(CC) -std=c23 -O3 $(CFLAGS) $(LDFLAGS) \
		$(shell PKG_CONFIG_PATH=./build/lib/pkgconfig pkg-config --libs-only-other $(FFMPEG_LIBS)) \
		$(shell PKG_CONFIG_PATH=./build/lib/pkgconfig pkg-config --libs-only-l $(FFMPEG_LIBS)) \
		scribe.c \
		-o $(BIN_OUTPUT_PATH)/scribe

bin:
	mkdir -p $(BIN_OUTPUT_PATH)

build: bin
	git submodule update --init
	mkdir -p build/include 
	mkdir -p build/lib
	mkdir -p build/share

$(RAYLIB_TARGET): build 
	cp raygui.h ./raylib/src/raylib.h ./raylib/src/rlgl.h ./raylib/src/raymath.h ./build/include
	cd raylib/src && RAYLIB_RELEASE_PATH=$(abspath build/lib) make -j$(NPROC) 


FFMPEG_CONFIG_OPTS = --prefix=../build \
		--enable-gpl \
		--disable-shared \
		--disable-programs \
		--disable-doc \
		--enable-static \
		--enable-decoder=mpeg4 \
		--enable-decoder=h264 \
		--enable-decoder=hevc \
		--enable-decoder=mjpeg \
		--enable-muxer=mov \
		--enable-muxer=mp4 \
		--enable-demuxer=mov \
		--enable-encoder=libx264 \
		--enable-encoder=mjpeg \
		--enable-encoder=mpeg4 \
		--enable-libx264 \
		--enable-parser=h264 \
		--enable-parser=hevc \
		--enable-protocol=file

$(FFMPEG_TARGET): build
	cd FFmpeg && \
		./configure $(FFMPEG_CONFIG_OPTS) && \
		make -j$(NPROC) && \
		make install

raygui.h: 
	wget https://raw.githubusercontent.com/raysan5/raygui/refs/heads/master/src/raygui.h

raylib:

FFmpeg:
	git submodule update --init

clean:
	rm -rf bin build 

clean-all:
	cd raylib/src && make clean 
	cd FFmpeg && make clean

