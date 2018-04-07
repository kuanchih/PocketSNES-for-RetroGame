TARGET = bin/PocketSNES

CROSS_COMPILE = mipsel-linux-
CC  := $(CROSS_COMPILE)gcc
CXX := $(CROSS_COMPILE)g++
STRIP := $(CROSS_COMPILE)strip

SYSROOT := $(shell $(CC) --print-sysroot)
SDL_CFLAGS := $(shell $(SYSROOT)/usr/bin/sdl-config --cflags)
SDL_LIBS := $(shell $(SYSROOT)/usr/bin/sdl-config --libs)

ifdef V
	CMD:=
	SUM:=@\#
else
	CMD:=@
	SUM:=@echo
endif
OPTIMIZE =  -O2 -mips32 -march=mips32 -mno-mips16 -fomit-frame-pointer -fno-builtin   \
            -fno-common -Wno-write-strings -Wno-sign-compare -ffast-math -ftree-vectorize \
			-funswitch-loops -fno-strict-aliasing
INCLUDE = -I pocketsnes \
		-I sal/linux/include -I sal/include \
		-I pocketsnes/include \
		-I menu -I pocketsnes/linux -I pocketsnes/snes9x \
		

CFLAGS = $(INCLUDE) -DRC_OPTIMIZED -D__LINUX__ -D__DINGUX__ -DNO_ROM_BROWSER \
		 -DGCW_ZERO \
		 -DMIPS_XBURST \
		 -DFAST_LSB_WORD_ACCESS \
		 -g -O2 -pipe  $(SDL_CFLAGS) \
		 -flto $(OPTIMIZE)

CXXFLAGS = $(CFLAGS) -fno-exceptions -fno-rtti

LDFLAGS = $(CXXFLAGS) -lpthread -lz -lpng -lm -lgcc $(SDL_LIBS)

# Find all source files
SOURCE = pocketsnes/snes9x menu sal/linux sal
SRC_CPP = $(foreach dir, $(SOURCE), $(wildcard $(dir)/*.cpp))
SRC_C   = $(foreach dir, $(SOURCE), $(wildcard $(dir)/*.c))
OBJ_CPP = $(patsubst %.cpp, %.o, $(SRC_CPP))
OBJ_C   = $(patsubst %.c, %.o, $(SRC_C))
OBJS    = $(OBJ_CPP) $(OBJ_C)

.PHONY : all
all : $(TARGET)

.PHONY: opk
opk: $(TARGET).opk

$(TARGET) : $(OBJS)
	$(SUM) "  LD      $@"
	$(CMD)$(CXX) $(CXXFLAGS) $^ $(LDFLAGS) -o $@

$(TARGET).opk: $(TARGET)
	$(SUM) "  OPK     $@"
	$(CMD)rm -rf .opk_data
	$(CMD)cp -r data .opk_data
	$(CMD)cp $< .opk_data/pocketsnes.gcw0
	$(CMD)$(STRIP) .opk_data/pocketsnes.gcw0
	$(CMD)mksquashfs .opk_data $@ -all-root -noappend -no-exports -no-xattrs -no-progress >/dev/null

%.o: %.c
	$(SUM) "  CC      $@"
	$(CMD)$(CC) $(CFLAGS) -c $< -o $@

%.o: %.cpp
	$(SUM) "  CXX     $@"
	$(CMD)$(CXX) $(CFLAGS) -c $< -o $@

.PHONY : clean
clean :
	$(SUM) "  CLEAN   ."
	$(CMD)rm -f $(OBJS) $(TARGET)
	$(CMD)rm -rf .opk_data $(TARGET).opk
