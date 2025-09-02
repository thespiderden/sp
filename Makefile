.POSIX:

override SPCOMP64="${HOME}/.local/share/sourcemod/scripting/spcomp64"
REF := $(shell ( git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD ) | sed 1q)
VERSION := $(shell (git diff-index --quiet HEAD -- && echo ${REF} || echo ${REF}"*"))
PLUGINS = $(shell ls scripting/*.sp | xargs -I % basename % .sp)

all: $(PLUGINS)

$(PLUGINS):
	mkdir -p plugins
	${SPCOMP64} scripting/$@.sp VERSION=\"${VERSION}\" -o plugins/$@.smx
