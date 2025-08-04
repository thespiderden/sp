override SPCOMP64="${HOME}/.local/share/sourcemod/scripting/spcomp64"
classconsciousness: scripting/classconsciousness.sp
	mkdir -p plugins
	${SPCOMP64} scripting/classconsciousness.sp -o plugins/classconsciousness.smx

zensitive: scripting/zensitive.sp
	mkdir -p plugins
	${SPCOMP64} scripting/zensitive.sp -o plugins/zensitive.smx
