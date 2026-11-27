package funkin.util.mobile;

#if android
@:keep
@:buildXml('
<files id="haxe">
  <compilerflag value="-fdata-sections" unless="debug" />
</files>
<target id="haxe">
  <flag value="-Wl,--gc-sections" unless="debug" />
  <flag value="-Wl,--icf=safe" unless="debug" />
  <flag value="-Wl,-O2" unless="debug" />
  <flag value="-Wl,--strip-all" unless="debug || HXCPP_DEBUG_LINK" />
</target>
')
class NativeBuildFlags {}
#end
