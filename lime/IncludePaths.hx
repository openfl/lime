package lime;

@:buildXml("
   <files id='haxe'>
      <compilerflag value='-I${haxelib:lime}/include'/>
   </files>
")
@:keep
class IncludePaths {}
