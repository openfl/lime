package lime.graphics.dom;
#if js
typedef DOMRenderContext = js.html.DivElement;
#else


typedef Attr = Dynamic;
typedef ClientRect = Dynamic;
typedef ClientRectList = Dynamic;
typedef CSSStyleDeclaration = Dynamic;
typedef Document = Dynamic;
typedef DOMTokenList = Dynamic;
typedef Element = Dynamic;
typedef Event = Dynamic;
typedef EventListener = Dynamic;
typedef HTMLCollection = Dynamic;
typedef NamedNodeMap = Dynamic;
typedef Node = Dynamic;
typedef NodeList = Dynamic;


class DOMRenderContext {
	
	
	public var accessKey:String;
	public var align:String;
	public var attributes (default, null):NamedNodeMap;
	public var baseURI (default, null):String;
	public var childElementCount (default, null):Int;
	public var childNodes (default, null):NodeList;
	public var children (default, null):HTMLCollection;
	public var classList (default, null):DOMTokenList;
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
	public var firstChild (default, null):Node;
	public var firstElementChild (default, null):Element;
	public var hidden:Bool;
	public var id:String;
	public var innerHTML:String;
	public var innerText:String;
	public var isContentEditable (default, null):Bool;
	public var lang:String;
	public var lastChild (default, null):Node;
	public var lastElementChild (default, null):Element;
	public var localName (default, null):String;
	public var namespaceURI (default, null):String;
	public var nextElementSibling (default, null):Element;
	public var nextSibling (default, null):Node;
	public var nodeName (default, null):String;
	public var nodeType (default, null):Int;
	public var nodeValue:String;
	public var offsetHeight (default, null):Int;
	public var offsetLeft (default, null):Int;
	public var offsetParent (default, null):Element;
	public var offsetTop (default, null):Int;
	public var offsetWidth (default, null):Int;
	public var onabort:EventListener;
	public var onbeforecopy:EventListener;
	public var onbeforecut:EventListener;
	public var onbeforepaste:EventListener;
	public var onblur:EventListener;
	public var onchange:EventListener;
	public var onclick:EventListener;
	public var oncontextmenu:EventListener;
	public var oncopy:EventListener;
	public var oncut:EventListener;
	public var ondblclick:EventListener;
	public var ondrag:EventListener;
	public var ondragend:EventListener;
	public var ondragenter:EventListener;
	public var ondragleave:EventListener;
	public var ondragover:EventListener;
	public var ondragstart:EventListener;
	public var ondrop:EventListener;
	public var onerror:EventListener;
	public var onfocus:EventListener;
	public var onfullscreenchange:EventListener;
	public var onfullscreenerror:EventListener;
	public var oninput:EventListener;
	public var oninvalid:EventListener;
	public var onkeydown:EventListener;
	public var onkeypress:EventListener;
	public var onkeyup:EventListener;
	public var onload:EventListener;
	public var onmousedown:EventListener;
	public var onmousemove:EventListener;
	public var onmouseout:EventListener;
	public var onmouseover:EventListener;
	public var onmouseup:EventListener;
	public var onmousewheel:EventListener;
	public var onpaste:EventListener;
	public var onreset:EventListener;
	public var onscroll:EventListener;
	public var onsearch:EventListener;
	public var onselect:EventListener;
	public var onselectstart:EventListener;
	public var onsubmit:EventListener;
	public var ontouchcancel:EventListener;
	public var ontouchend:EventListener;
	public var ontouchmove:EventListener;
	public var ontouchstart:EventListener;
	public var outerHTML:String;
	public var outerText:String;
	public var ownerDocument (default, null):Document;
	public var parentElement (default, null):Element;
	public var parentNode (default, null):Node;
	public var prefix:String;
	public var previousElementSibling (default, null):Element;
	public var previousSibling (default, null):Node;
	public var pseudo:String;
	public var scrollHeight (default, null):Int;
	public var scrollLeft:Int;
	public var scrollTop:Int;
	public var scrollWidth (default, null):Int;
	public var spellcheck:Bool;
	public var style (default, null):CSSStyleDeclaration;
	public var tabIndex:Int;
	public var tagName (default, null):String;
	public var textContent:String;
	public var title:String;
	public var translate:Bool;
	
	
	public function new () {
		
		
		
	}
	
	
	public function addEventListener (type:String, listener:EventListener, ?useCapture:Bool):Void {};
	public function appendChild (newChild:Node):Node { return null; };
	public function blur ():Void {};
	public function click ():Void {};
	public function cloneNode (deep:Bool):Node { return null; };
	public function compareDocumentPosition (other:Node):Int { return -1; };
	public function contains (other:Node):Bool { return false; };
	public function dispatchEvent (event:Event):Bool { return false; };
	public function focus ():Void {};
	public function getAttribute (name:String):String { return null; };
	public function getAttributeNS (?namespaceURI:String, localName:String):String { return null; };
	public function getAttributeNode (name:String):Attr { return null; };
	public function getAttributeNodeNS (?namespaceURI:String, localName:String):Attr { return null; };
	public function getBoundingClientRect ():ClientRect { return null; };
	public function getClientRects ():ClientRectList { return null; };
	public function getElementsByClassName (name:String):NodeList { return null; };
	public function getElementsByTagName (name:String):NodeList { return null; };
	public function getElementsByTagNameNS (?namespaceURI:String, localName:String):NodeList { return null; };
	public function hasAttribute (name:String):Bool { return false; };
	public function hasAttributeNS (?namespaceURI:String, localName:String):Bool { return false; };
	public function hasAttributes ():Bool { return false; };
	public function hasChildNodes ():Bool { return false; };
	public function insertAdjacentElement (where:String, element:Element):Element { return null; };
	public function insertAdjacentHTML (where:String, html:String):Void {};
	public function insertAdjacentText (where:String, text:String):Void {};
	public function insertBefore (newChild:Node, refChild:Node):Node { return null; };
	public function isDefaultNamespace (?namespaceURI:String):Bool { return false; };
	public function isEqualNode (other:Node):Bool { return false; };
	public function isSameNode (other:Node):Bool { return false; };
	public function isSupported (feature:String, ?version:String):Bool { return false; };
	public function lookupNamespaceURI (?prefix:String):String { return null; };
	public function lookupPrefix (?namespaceURI:String):String { return null; };
	public function matchesSelector (selectors:String):Bool { return false; };
	public function normalize ():Void {};
	public function querySelector (selectors:String):Element { return null; };
	public function querySelectorAll (selectors:String):NodeList { return null; };
	public function remove ():Void {};
	public function removeAttribute (name:String):Void {};
	public function removeAttributeNS (namespaceURI:String, localName:String):Void {};
	public function removeAttributeNode (oldAttr:Attr):Attr { return null; };
	public function removeChild (oldChild:Node):Node { return null; };
	public function removeEventListener (type:String, listener:EventListener, ?useCapture:Bool):Void {};
	public function replaceChild (newChild:Node, oldChild:Node):Node { return null; };
	public function requestFullScreen (flags:Int):Void {};
	public function requestFullscreen ():Void {};
	public function requestPointerLock ():Void {};
	public function scrollByLines (lines:Int):Void {};
	public function scrollByPages (pages:Int):Void {};
	public function scrollIntoView (?alignWithTop:Bool):Void {};
	public function scrollIntoViewIfNeeded (?centerIfNeeded:Bool):Void {};
	public function setAttribute (name:String, value:String):Void {};
	public function setAttributeNS (?namespaceURI:String, qualifiedName:String, value:String):Void {};
	public function setAttributeNode (newAttr:Attr):Attr { return null; };
	public function setAttributeNodeNS (newAttr:Attr):Attr { return null; };
	
	
}


#end