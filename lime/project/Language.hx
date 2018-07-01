package lime.project;

import lime.tools.helpers.ArrayHelper;

class Language {
	public var supported: Array<String>;
	public function new(?supported: Array<String>) {
		if (supported != null) {
			this.supported = supported;
		} else {
			this.supported = [];	
		}
	}
	public function clone(): Language {
		return new Language(supported.copy());
	}
	public function merge(languageToMerge: Language) {
		supported = ArrayHelper.concatUnique (supported, languageToMerge.supported);
	}
}
