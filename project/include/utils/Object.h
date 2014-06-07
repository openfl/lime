#ifndef LIME_UTILS_OBJECT_H
#define LIME_UTILS_OBJECT_H


namespace lime {
	
	
	class Object {
		
		
		public:
			
			int ref_count;
		
		protected:
			
			virtual ~Object () {}
		
		public:
			
			Object (bool has_initial_ref = false) : ref_count (has_initial_ref ? 1 : 0) {}
			
			Object *grab () {
				
				ref_count++;
				
				return this; 
				
			}
			
			void drop () { 
				
				ref_count--; 
				
				if (ref_count <= 0) {
					delete this; 
				}
				
			}
		
		
	};
	
	
}


#endif