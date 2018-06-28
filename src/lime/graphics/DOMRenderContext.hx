package lime.graphics;
#if (js && html5 && !doc_gen)
typedef DOMRenderContext = js.html.DivElement;
#else


class DOMRenderContext {
	
	
	public var accessKey:String;
	public var align:String;
	public var attributes (default, null):Dynamic /*NamedNodeMap*/;
	public var baseURI (default, null):String;
	public var childElementCount (default, null):Int;
	public var childNodes (default, null):Dynamic /*NodeList*/;
	public var children (default, null):Dynamic /*HTMLCollection*/;
	public var classList (default, null):Dynamic /*DOMTokenList*/;
	public var className:String;
	public var clientHeight (default, null):Int;
	public var clientLeft (default, null):Int;
	public var clientTop (default, null):Int;
	public var clientWidth (default, null):Int;
	public var contentEditable:String;
	public var dataset (default, null):Dynamic<String>;
	public var dir:String;
	public var draggable:Bool;
	public var dropzone:String;
	public var firstChild (default, null):Dynamic /*Node*/;
	public var firstElementChild (default, null):Dynamic /*Element*/;
	public var hidden:Bool;
	public var id:String;
	public var innerHTML:String;
	public var innerText:String;
	public var isContentEditable (default, null):Bool;
	public var lang:String;
	public var lastChild (default, null):Dynamic /*Node*/;
	public var lastElementChild (default, null):Dynamic /*Element*/;
	public var localName (default, null):String;
	public var namespaceURI (default, null):String;
	public var nextElementSibling (default, null):Dynamic /*Element*/;
	public var nextSibling (default, null):Dynamic /*Node*/;
	public var nodeName (default, null):String;
	public var nodeType (default, null):Int;
	public var nodeValue:String;
	public var offsetHeight (default, null):Int;
	public var offsetLeft (default, null):Int;
	public var offsetParent (default, null):Dynamic /*Element*/;
	public var offsetTop (default, null):Int;
	public var offsetWidth (default, null):Int;
	public var onabort:Dynamic /*EventListener*/;
	public var onbeforecopy:Dynamic /*EventListener*/;
	public var onbeforecut:Dynamic /*EventListener*/;
	public var onbeforepaste:Dynamic /*EventListener*/;
	public var onblur:Dynamic /*EventListener*/;
	public var onchange:Dynamic /*EventListener*/;
	public var onclick:Dynamic /*EventListener*/;
	public var oncontextmenu:Dynamic /*EventListener*/;
	public var oncopy:Dynamic /*EventListener*/;
	public var oncut:Dynamic /*EventListener*/;
	public var ondblclick:Dynamic /*EventListener*/;
	public var ondrag:Dynamic /*EventListener*/;
	public var ondragend:Dynamic /*EventListener*/;
	public var ondragenter:Dynamic /*EventListener*/;
	public var ondragleave:Dynamic /*EventListener*/;
	public var ondragover:Dynamic /*EventListener*/;
	public var ondragstart:Dynamic /*EventListener*/;
	public var ondrop:Dynamic /*EventListener*/;
	public var onerror:Dynamic /*EventListener*/;
	public var onfocus:Dynamic /*EventListener*/;
	public var onfullscreenchange:Dynamic /*EventListener*/;
	public var onfullscreenerror:Dynamic /*EventListener*/;
	public var oninput:Dynamic /*EventListener*/;
	public var oninvalid:Dynamic /*EventListener*/;
	public var onkeydown:Dynamic /*EventListener*/;
	public var onkeypress:Dynamic /*EventListener*/;
	public var onkeyup:Dynamic /*EventListener*/;
	public var onload:Dynamic /*EventListener*/;
	public var onmousedown:Dynamic /*EventListener*/;
	public var onmousemove:Dynamic /*EventListener*/;
	public var onmouseout:Dynamic /*EventListener*/;
	public var onmouseover:Dynamic /*EventListener*/;
	public var onmouseup:Dynamic /*EventListener*/;
	public var onmousewheel:Dynamic /*EventListener*/;
	public var onpaste:Dynamic /*EventListener*/;
	public var onreset:Dynamic /*EventListener*/;
	public var onscroll:Dynamic /*EventListener*/;
	public var onsearch:Dynamic /*EventListener*/;
	public var onselect:Dynamic /*EventListener*/;
	public var onselectstart:Dynamic /*EventListener*/;
	public var onsubmit:Dynamic /*EventListener*/;
	public var ontouchcancel:Dynamic /*EventListener*/;
	public var ontouchend:Dynamic /*EventListener*/;
	public var ontouchmove:Dynamic /*EventListener*/;
	public var ontouchstart:Dynamic /*EventListener*/;
	public var outerHTML:String;
	public var outerText:String;
	public var ownerDocument (default, null):Dynamic /*Document*/;
	public var parentElement (default, null):Dynamic /*Element*/;
	public var parentNode (default, null):Dynamic /*Node*/;
	public var prefix:String;
	public var previousElementSibling (default, null):Dynamic /*Element*/;
	public var previousSibling (default, null):Dynamic /*Node*/;
	public var pseudo:String;
	public var scrollHeight (default, null):Int;
	public var scrollLeft:Int;
	public var scrollTop:Int;
	public var scrollWidth (default, null):Int;
	public var spellcheck:Bool;
	public var style (default, null):Dynamic /*CSSStyleDeclaration*/;
	public var tabIndex:Int;
	public var tagName (default, null):String;
	public var textContent:String;
	public var title:String;
	public var translate:Bool;
	
	
	public function new () {
		
		
		
	}
	
	
	public function addEventListener (type:String, listener:Dynamic /*EventListener*/, ?useCapture:Bool):Void {};
	public function appendChild (newChild:Dynamic /*Node*/):Dynamic /*Node*/ { return null; };
	public function blur ():Void {};
	public function click ():Void {};
	public function cloneNode (deep:Bool):Dynamic /*Node*/ { return null; };
	public function compareDocumentPosition (other:Dynamic /*Node*/):Int { return -1; };
	public function contains (other:Dynamic /*Node*/):Bool { return false; };
	public function dispatchEvent (event:Dynamic /*Event*/):Bool { return false; };
	public function focus ():Void {};
	public function getAttribute (name:String):String { return null; };
	public function getAttributeNS (?namespaceURI:String, localName:String):String { return null; };
	public function getAttributeNode (name:String):Dynamic /*Attr*/ { return null; };
	public function getAttributeNodeNS (?namespaceURI:String, localName:String):Dynamic /*Attr*/ { return null; };
	public function getBoundingClientRect ():Dynamic /*ClientRect*/ { return null; };
	public function getClientRects ():Dynamic /*ClientRectList*/ { return null; };
	public function getElementsByClassName (name:String):Dynamic /*NodeList*/ { return null; };
	public function getElementsByTagName (name:String):Dynamic /*NodeList*/ { return null; };
	public function getElementsByTagNameNS (?namespaceURI:String, localName:String):Dynamic /*NodeList*/ { return null; };
	public function hasAttribute (name:String):Bool { return false; };
	public function hasAttributeNS (?namespaceURI:String, localName:String):Bool { return false; };
	public function hasAttributes ():Bool { return false; };
	public function hasChildNodes ():Bool { return false; };
	public function insertAdjacentElement (where:String, element:Dynamic /*Element*/):Dynamic /*Element*/ { return null; };
	public function insertAdjacentHTML (where:String, html:String):Void {};
	public function insertAdjacentText (where:String, text:String):Void {};
	public function insertBefore (newChild:Dynamic /*Node*/, refChild:Dynamic /*Node*/):Dynamic /*Node*/ { return null; };
	public function isDefaultNamespace (?namespaceURI:String):Bool { return false; };
	public function isEqualNode (other:Dynamic /*Node*/):Bool { return false; };
	public function isSameNode (other:Dynamic /*Node*/):Bool { return false; };
	public function isSupported (feature:String, ?version:String):Bool { return false; };
	public function lookupNamespaceURI (?prefix:String):String { return null; };
	public function lookupPrefix (?namespaceURI:String):String { return null; };
	public function matchesSelector (selectors:String):Bool { return false; };
	public function normalize ():Void {};
	public function querySelector (selectors:String):Dynamic /*Element*/ { return null; };
	public function querySelectorAll (selectors:String):Dynamic /*NodeList*/ { return null; };
	public function remove ():Void {};
	public function removeAttribute (name:String):Void {};
	public function removeAttributeNS (namespaceURI:String, localName:String):Void {};
	public function removeAttributeNode (oldAttr:Dynamic /*Attr*/):Dynamic /*Attr*/ { return null; };
	public function removeChild (oldChild:Dynamic /*Node*/):Dynamic /*Node*/ { return null; };
	public function removeEventListener (type:String, listener:Dynamic /*EventListener*/, ?useCapture:Bool):Void {};
	public function replaceChild (newChild:Dynamic /*Node*/, oldChild:Dynamic /*Node*/):Dynamic /*Node*/ { return null; };
	public function requestFullScreen (flags:Int):Void {};
	public function requestFullscreen ():Void {};
	public function requestPointerLock ():Void {};
	public function scrollByLines (lines:Int):Void {};
	public function scrollByPages (pages:Int):Void {};
	public function scrollIntoView (?alignWithTop:Bool):Void {};
	public function scrollIntoViewIfNeeded (?centerIfNeeded:Bool):Void {};
	public function setAttribute (name:String, value:String):Void {};
	public function setAttributeNS (?namespaceURI:String, qualifiedName:String, value:String):Void {};
	public function setAttributeNode (newAttr:Dynamic /*Attr*/):Dynamic /*Attr*/ { return null; };
	public function setAttributeNodeNS (newAttr:Dynamic /*Attr*/):Dynamic /*Attr*/ { return null; };
	
	
}


#end