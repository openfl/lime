#include <system/CFFI.h>
#include <system/CFFIPointer.h>

// A workaround for the GL Bindings that the framework setup.

namespace lime {

    void lime_gl_active_texture(int texture) {}

    void lime_gl_attach_shader(int program, int shader) {}

    void lime_gl_begin_query(int target, int query) {}

    void lime_gl_begin_transform_feedback(int primitiveMode) {}

    void lime_gl_bind_attrib_location(int program, int index, HxString name) {}

    void lime_gl_bind_buffer(int target, int buffer) {}

    void lime_gl_bind_buffer_base(int target, int index, int buffer) {}

    void lime_gl_bind_buffer_range(int target, int index, int buffer, double offset, int size) {}

    void lime_gl_bind_framebuffer(int target, int framebuffer) {}

    void lime_gl_bind_renderbuffer(int target, int renderbuffer) {}

    void lime_gl_bind_sampler(int unit, int sampler) {}

    void lime_gl_bind_texture(int target, int texture) {}

    void lime_gl_bind_transform_feedback(int target, int id) {}

    void lime_gl_bind_vertex_array(int vertexArray) {}

    void lime_gl_blend_color(float red, float green, float blue, float alpha) {}

    void lime_gl_blend_equation(int mode) {}

    void lime_gl_blend_equation_separate(int modeRGB, int modeAlpha) {}

    void lime_gl_blend_func(int sfactor, int dfactor) {}

    void lime_gl_blend_func_separate(int srcRGB, int dstRGB, int srcAlpha, int dstAlpha) {}

    void
    lime_gl_blit_framebuffer(int srcX0, int srcY0, int srcX1, int srcY1, int dstX0, int dstY0, int dstX1, int dstY1,
                             int mask, int filter) {}

    void lime_gl_buffer_data(int target, int size, double data, int usage) {}

    void lime_gl_buffer_sub_data(int target, int offset, int size, double data) {}

    int lime_gl_check_framebuffer_status(int target) { return 0; }

    void lime_gl_clear(int mask) {}

    void lime_gl_clear_bufferfi(int buffer, int drawbuffer, float depth, int stencil) {}

    void lime_gl_clear_bufferfv(int buffer, int drawbuffer, double value) {}

    void lime_gl_clear_bufferiv(int buffer, int drawbuffer, double value) {}

    void lime_gl_clear_bufferuiv(int buffer, int drawbuffer, double value) {}

    void lime_gl_clear_color(float red, float green, float blue, float alpha) {}

    void lime_gl_clear_depthf(float depth) {}

    void lime_gl_clear_stencil(int s) {}

    int lime_gl_client_wait_sync(value sync, int flags, int timeoutA, int timeoutB) { return 0; }

    void lime_gl_color_mask(bool red, bool green, bool blue, bool alpha) {}

    void lime_gl_compile_shader(int shader) {}

    void lime_gl_compressed_tex_image_2d(int target, int level, int internalformat, int width, int height, int border,
                                         int imageSize, double data) {}

    void lime_gl_compressed_tex_image_3d(int target, int level, int internalformat, int width, int height, int depth,
                                         int border, int imageSize, double data) {}

    void lime_gl_compressed_tex_sub_image_2d(int target, int level, int xoffset, int yoffset, int width, int height,
                                             int format, int imageSize, double data) {}

    void lime_gl_compressed_tex_sub_image_3d(int target, int level, int xoffset, int yoffset, int zoffset, int width,
                                             int height, int depth, int format, int imageSize, double data) {}

    void
    lime_gl_copy_buffer_sub_data(int readTarget, int writeTarget, double readOffset, double writeOffset, int size) {}

    void lime_gl_copy_tex_image_2d(int target, int level, int internalformat, int x, int y, int width, int height,
                                   int border) {}

    void lime_gl_copy_tex_sub_image_2d(int target, int level, int xoffset, int yoffset, int x, int y, int width,
                                       int height) {}

    void
    lime_gl_copy_tex_sub_image_3d(int target, int level, int xoffset, int yoffset, int zoffset, int x, int y, int width,
                                  int height) {}

    int lime_gl_create_buffer() { return 0; }

    int lime_gl_create_framebuffer() { return 0; }

    int lime_gl_create_program() { return 0; }

    int lime_gl_create_query() { return 0; }

    int lime_gl_create_renderbuffer() { return 0; }

    int lime_gl_create_sampler() { return 0; }

    int lime_gl_create_shader(int type) { return 0; }

    int lime_gl_create_texture() { return 0; }

    int lime_gl_create_transform_feedback() { return 0; }

    int lime_gl_create_vertex_array() { return 0; }

    void lime_gl_cull_face(int mode) {}

    void lime_gl_delete_buffer(int buffer) {}

    void lime_gl_delete_framebuffer(int framebuffer) {}

    void lime_gl_delete_program(int program) {}

    void lime_gl_delete_query(int query) {}

    void lime_gl_delete_renderbuffer(int renderbuffer) {}

    void lime_gl_delete_sampler(int sampler) {}

    void lime_gl_delete_shader(int shader) {}

    void lime_gl_delete_sync(value sync) {}

    void lime_gl_delete_texture(int texture) {}

    void lime_gl_delete_transform_feedback(int id) {}

    void lime_gl_delete_vertex_array(int vertexArray) {}

    void lime_gl_depth_func(int func) {}

    void lime_gl_depth_mask(bool flag) {}

    void lime_gl_depth_rangef(float zNear, float zFar) {}

    void lime_gl_detach_shader(int program, int shader) {}

    void lime_gl_disable(int cap) {}

    void lime_gl_disable_vertex_attrib_array(int index) {}

    void lime_gl_draw_arrays(int mode, int first, int count) {}

    void lime_gl_draw_arrays_instanced(int mode, int first, int count, int instanceCount) {}

    void lime_gl_draw_buffers(value buffers) {}

    void lime_gl_draw_elements(int mode, int count, int type, double offset) {}

    void lime_gl_draw_elements_instanced(int mode, int count, int type, double offset, int instanceCount) {}

    void lime_gl_draw_range_elements(int mode, int start, int end, int count, int type, double offset) {}

    void lime_gl_enable(int cap) {}

    void lime_gl_enable_vertex_attrib_array(int index) {}

    void lime_gl_end_query(int target) {}

    void lime_gl_end_transform_feedback() {}

    value lime_gl_fence_sync(int condition, int flags) { return alloc_null(); }

    void lime_gl_finish() {}

    void lime_gl_flush() {}

    void lime_gl_framebuffer_renderbuffer(int target, int attachment, int renderbuffertarget, int renderbuffer) {}

    void lime_gl_framebuffer_texture2D(int target, int attachment, int textarget, int texture, int level) {}

    void lime_gl_framebuffer_texture_layer(int target, int attachment, int texture, int level, int layer) {}

    void lime_gl_front_face(int mode) {}

    void lime_gl_generate_mipmap(int target) {}

    value lime_gl_get_active_attrib(int program, int index) { return alloc_null(); }

    value lime_gl_get_active_uniform(int program, int index) { return alloc_null(); }

    int lime_gl_get_active_uniform_blocki(int program, int uniformBlockIndex, int pname) { return 0; }

    void lime_gl_get_active_uniform_blockiv(int program, int uniformBlockIndex, int pname, double params) {}

    value lime_gl_get_active_uniform_block_name(int program, int uniformBlockIndex) { return alloc_null(); }

    void lime_gl_get_active_uniformsiv(int program, value uniformIndices, int pname, double params) {}

    value lime_gl_get_attached_shaders(int program) { return alloc_null(); }

    int lime_gl_get_attrib_location(int program, HxString name) { return 0; }

    bool lime_gl_get_boolean(int pname) { return false; }

    void lime_gl_get_booleanv(int pname, double params) {}

    int lime_gl_get_buffer_parameteri(int target, int pname) { return 0; }

    void lime_gl_get_buffer_parameteri64v(int target, int index, double params) {}

    void lime_gl_get_buffer_parameteriv(int target, int pname, double params) {}

    double lime_gl_get_buffer_pointerv(int target, int pname) { return 0; }

    void lime_gl_get_buffer_sub_data(int target, double offset, int size, double data) {}

    value lime_gl_get_context_attributes() { return alloc_null(); }

    int lime_gl_get_error() { return 0; }

    value lime_gl_get_extension(HxString name) { return alloc_null(); }

    float lime_gl_get_float(int pname) { return 0; }

    void lime_gl_get_floatv(int pname, double params) {}

    int lime_gl_get_frag_data_location(int program, HxString name) { return 0; }

    int lime_gl_get_framebuffer_attachment_parameteri(int target, int attachment, int pname) { return 0; }

    void lime_gl_get_framebuffer_attachment_parameteriv(int target, int attachment, int pname, double params) {}

    int lime_gl_get_integer(int pname) { return 0; }

    void lime_gl_get_integer64v(int pname, double params) {}

    void lime_gl_get_integer64i_v (int pname, int index, double params) {}

    void lime_gl_get_integeri_v(int pname, int index, double params) {}

    void lime_gl_get_integerv(int pname, double params) {}

    void lime_gl_get_internalformativ(int target, int internalformat, int pname, int bufSize, double params) {}

    void lime_gl_get_program_binary(int program, int binaryFormat, value bytes) {}

    value lime_gl_get_program_info_log(int handle) { return alloc_null(); }

    int lime_gl_get_programi(int program, int pname) { return 0; }

    void lime_gl_get_programiv(int program, int pname, double params) {}

    int lime_gl_get_queryi(int target, int pname) { return 0; }

    void lime_gl_get_queryiv(int target, int pname, double params) {}

    int lime_gl_get_query_objectui(int query, int pname) { return 0; }

    void lime_gl_get_query_objectuiv(int query, int pname, double params) {}

    int lime_gl_get_renderbuffer_parameteri(int target, int pname) { return 0; }

    void lime_gl_get_renderbuffer_parameteriv(int target, int pname, double params) {}

    float lime_gl_get_sampler_parameterf(int sampler, int pname) { return 0; }

    void lime_gl_get_sampler_parameterfv(int sampler, int pname, double params) {}

    int lime_gl_get_sampler_parameteri(int sampler, int pname) { return 0; }

    void lime_gl_get_sampler_parameteriv(int sampler, int pname, double params) {}

    value lime_gl_get_shader_info_log(int handle) { return alloc_null(); }

    int lime_gl_get_shaderi(int shader, int pname) { return 0; }

    void lime_gl_get_shaderiv(int shader, int pname, double params) {}

    value lime_gl_get_shader_precision_format(int shadertype, int precisiontype) { return 0; }

    value lime_gl_get_shader_source(int handle) { return alloc_null(); }

    value lime_gl_get_string(int pname) { return alloc_null(); }

    value lime_gl_get_stringi(int pname, int index) { return alloc_null(); }

    int lime_gl_get_sync_parameteri(value sync, int pname) { return 0; }

    void lime_gl_get_sync_parameteriv(value sync, int pname, double params) {}

    float lime_gl_get_tex_parameterf(int target, int pname) { return 0; }

    void lime_gl_get_tex_parameterfv(int target, int pname, double params) {}

    int lime_gl_get_tex_parameteri(int target, int pname) { return 0; }

    void lime_gl_get_tex_parameteriv(int target, int pname, double params) {}

    value lime_gl_get_transform_feedback_varying(int program, int index) { return alloc_null(); }

    float lime_gl_get_uniformf(int program, int location) { return 0; }

    void lime_gl_get_uniformfv(int program, int location, double params) {}

    int lime_gl_get_uniformi(int program, int location) { return 0; }

    void lime_gl_get_uniformiv(int program, int location, double params) {}

    int lime_gl_get_uniformui(int program, int location) { return 0; }

    void lime_gl_get_uniformuiv(int program, int location, double params) {}

    int lime_gl_get_uniform_block_index(int program, HxString uniformBlockName) { return 0; }

    int lime_gl_get_uniform_location(int program, HxString name) { return 0; }

    float lime_gl_get_vertex_attribf(int index, int pname) { return 0; }

    void lime_gl_get_vertex_attribfv(int index, int pname, double params) {}

    int lime_gl_get_vertex_attribi(int index, int pname) { return 0; }

    void lime_gl_get_vertex_attribiv(int index, int pname, double params) {}

    int lime_gl_get_vertex_attribii(int index, int pname) { return 0; }

    void lime_gl_get_vertex_attribiiv(int index, int pname, double params) {}

    int lime_gl_get_vertex_attribiui(int index, int pname) { return 0; }

    void lime_gl_get_vertex_attribiuiv(int index, int pname, double params) {}

    double lime_gl_get_vertex_attrib_pointerv(int index, int pname) { return 0; }

    void lime_gl_hint(int target, int mode) {}

    void lime_gl_invalidate_framebuffer(int target, value attachments) {}

    void lime_gl_invalidate_sub_framebuffer(int target, value attachments, int x, int y, int width, int height) {}

    bool lime_gl_is_buffer(int buffer) { return false; }

    bool lime_gl_is_enabled(int cap) { return false; }

    bool lime_gl_is_framebuffer(int framebuffer) { return false; }

    bool lime_gl_is_program(int program) { return false; }

    bool lime_gl_is_query(int query) { return false; }

    bool lime_gl_is_renderbuffer(int renderbuffer) { return false; }

    bool lime_gl_is_sampler(int sampler) { return false; }

    bool lime_gl_is_shader(int shader) { return false; }

    bool lime_gl_is_sync(value sync) { return false; }

    bool lime_gl_is_texture(int texture) { return false; }

    bool lime_gl_is_transform_feedback(int id) { return false; }

    bool lime_gl_is_vertex_array(int id) { return false; }

    void lime_gl_line_width(float width) {}

    void lime_gl_link_program(int program) {}

    double lime_gl_map_buffer_range(int target, double offset, int length, int access) { return 0; }

    void lime_gl_object_deregister(value object) {}

    value lime_gl_object_from_id(int id, int type) { return alloc_null(); }

    value lime_gl_object_register(int id, int type, value object) { return alloc_null(); }

    void lime_gl_pause_transform_feedback() {}

    void lime_gl_pixel_storei(int pname, int param) {}

    void lime_gl_polygon_offset(float factor, float units) {}

    void lime_gl_program_binary(int program, int binaryFormat, double binary, int length) {}

    void lime_gl_program_parameteri(int program, int pname, int value) {}

    void lime_gl_read_buffer(int src) {}

    void lime_gl_read_pixels(int x, int y, int width, int height, int format, int type, double pixels) {}

    void lime_gl_release_shader_compiler() {}

    void lime_gl_renderbuffer_storage(int target, int internalformat, int width, int height) {}

    void lime_gl_renderbuffer_storage_multisample(int target, int samples, int internalformat, int width, int height) {}

    void lime_gl_resume_transform_feedback() {}

    void lime_gl_sample_coverage(float value, bool invert) {}

    void lime_gl_sampler_parameterf(int sampler, int pname, float param) {}

    void lime_gl_sampler_parameteri(int sampler, int pname, int param) {}

    void lime_gl_scissor(int x, int y, int width, int height) {}

    void lime_gl_shader_binary(value shaders, int binaryformat, double binary, int length) {}

    void lime_gl_shader_source(int shader, HxString source) {}

    void lime_gl_stencil_func(int func, int ref, int mask) {}

    void lime_gl_stencil_func_separate(int face, int func, int ref, int mask) {}

    void lime_gl_stencil_mask(int mask) {}

    void lime_gl_stencil_mask_separate(int face, int mask) {}

    void lime_gl_stencil_op(int fail, int zfail, int zpass) {}

    void lime_gl_stencil_op_separate(int face, int fail, int zfail, int zpass) {}

    void lime_gl_tex_image_2d(int target, int level, int internalformat, int width, int height, int border, int format,
                              int type, double data) {}

    void lime_gl_tex_image_3d(int target, int level, int internalformat, int width, int height, int depth, int border,
                              int format, int type, double data) {}

    void lime_gl_tex_parameterf(int target, int pname, float param) {}

    void lime_gl_tex_parameteri(int target, int pname, int param) {}

    void lime_gl_tex_storage_2d(int target, int levels, int internalformat, int width, int height) {}

    void lime_gl_tex_storage_3d(int target, int levels, int internalformat, int width, int height, int depth) {}

    void lime_gl_tex_sub_image_2d(int target, int level, int xoffset, int yoffset, int width, int height, int format,
                                  int type, double data) {}

    void lime_gl_tex_sub_image_3d(int target, int level, int xoffset, int yoffset, int zoffset, int width, int height,
                                  int depth, int format, int type, double data) {}

    void lime_gl_transform_feedback_varyings(int program, value varyings, int bufferMode) {}

    void lime_gl_uniform1f(int location, float x) {}

    void lime_gl_uniform1fv(int location, int count, double _value) {}

    void lime_gl_uniform1i(int location, int x) {}

    void lime_gl_uniform1iv(int location, int count, double _value) {}

    void lime_gl_uniform1ui(int location, int x) {}

    void lime_gl_uniform1uiv(int location, int count, double _value) {}

    void lime_gl_uniform2f(int location, float x, float y) {}

    void lime_gl_uniform2fv(int location, int count, double _value) {}

    void lime_gl_uniform2i(int location, int x, int y) {}

    void lime_gl_uniform2iv(int location, int count, double _value) {}

    void lime_gl_uniform2ui(int location, int x, int y) {}

    void lime_gl_uniform2uiv(int location, int count, double _value) {}

    void lime_gl_uniform3f(int location, float x, float y, float z) {}

    void lime_gl_uniform3fv(int location, int count, double _value) {}

    void lime_gl_uniform3i(int location, int x, int y, int z) {}

    void lime_gl_uniform3iv(int location, int count, double _value) {}

    void lime_gl_uniform3ui(int location, int x, int y, int z) {}

    void lime_gl_uniform3uiv(int location, int count, double _value) {}

    void lime_gl_uniform4f(int location, float x, float y, float z, float w) {}

    void lime_gl_uniform4fv(int location, int count, double _value) {}

    void lime_gl_uniform4i(int location, int x, int y, int z, int w) {}

    void lime_gl_uniform4iv(int location, int count, double _value) {}

    void lime_gl_uniform4ui(int location, int x, int y, int z, int w) {}

    void lime_gl_uniform4uiv(int location, int count, double _value) {}

    void lime_gl_uniform_block_binding(int program, int uniformBlockIndex, int uniformBlockBinding) {}

    void lime_gl_uniform_matrix2fv(int location, int count, bool transpose, double _value) {}

    void lime_gl_uniform_matrix2x3fv(int location, int count, bool transpose, double _value) {}

    void lime_gl_uniform_matrix2x4fv(int location, int count, bool transpose, double _value) {}

    void lime_gl_uniform_matrix3fv(int location, int count, bool transpose, double _value) {}

    void lime_gl_uniform_matrix3x2fv(int location, int count, bool transpose, double _value) {}

    void lime_gl_uniform_matrix3x4fv(int location, int count, bool transpose, double _value) {}

    void lime_gl_uniform_matrix4fv(int location, int count, bool transpose, double _value) {}

    void lime_gl_uniform_matrix4x2fv(int location, int count, bool transpose, double _value) {}

    void lime_gl_uniform_matrix4x3fv(int location, int count, bool transpose, double _value) {}

    bool lime_gl_unmap_buffer(int target) { return false; }

    void lime_gl_use_program(int program) {}

    void lime_gl_validate_program(int program) {}

    void lime_gl_vertex_attrib_divisor(int index, int divisor) {}

    void lime_gl_vertex_attrib_ipointer(int index, int size, int type, int stride, double offset) {}

    void lime_gl_vertex_attrib_pointer(int index, int size, int type, bool normalized, int stride, double offset) {}

    void lime_gl_vertex_attribi4i(int index, int v0, int v1, int v2, int v3) {}

    void lime_gl_vertex_attribi4iv(int index, double value) {}

    void lime_gl_vertex_attribi4ui(int index, int v0, int v1, int v2, int v3) {}

    void lime_gl_vertex_attribi4uiv(int index, double value) {}

    void lime_gl_vertex_attrib1f(int index, float v0) {}

    void lime_gl_vertex_attrib1fv(int index, double value) {}

    void lime_gl_vertex_attrib2f(int index, float v0, float v1) {}

    void lime_gl_vertex_attrib2fv(int index, double value) {}

    void lime_gl_vertex_attrib3f(int index, float v0, float v1, float v2) {}

    void lime_gl_vertex_attrib3fv(int index, double value) {}

    void lime_gl_vertex_attrib4f(int index, float v0, float v1, float v2, float v3) {}

    void lime_gl_vertex_attrib4fv(int index, double value) {}

    void lime_gl_viewport(int x, int y, int width, int height) {}

    void lime_gl_wait_sync(value sync, int flags, int timeoutA, int timeoutB) {}


    DEFINE_PRIME1v (lime_gl_active_texture);
    DEFINE_PRIME2v (lime_gl_attach_shader);
    DEFINE_PRIME2v (lime_gl_begin_query);
    DEFINE_PRIME1v (lime_gl_begin_transform_feedback);
    DEFINE_PRIME3v (lime_gl_bind_attrib_location);
    DEFINE_PRIME2v (lime_gl_bind_buffer);
    DEFINE_PRIME3v (lime_gl_bind_buffer_base);
    DEFINE_PRIME5v (lime_gl_bind_buffer_range);
    DEFINE_PRIME2v (lime_gl_bind_framebuffer);
    DEFINE_PRIME2v (lime_gl_bind_renderbuffer);
    DEFINE_PRIME2v (lime_gl_bind_sampler);
    DEFINE_PRIME2v (lime_gl_bind_texture);
    DEFINE_PRIME2v (lime_gl_bind_transform_feedback);
    DEFINE_PRIME1v (lime_gl_bind_vertex_array);
    DEFINE_PRIME4v (lime_gl_blend_color);
    DEFINE_PRIME1v (lime_gl_blend_equation);
    DEFINE_PRIME2v (lime_gl_blend_equation_separate);
    DEFINE_PRIME2v (lime_gl_blend_func);
    DEFINE_PRIME4v (lime_gl_blend_func_separate);
    DEFINE_PRIME10v (lime_gl_blit_framebuffer);
    DEFINE_PRIME4v (lime_gl_buffer_data);
    DEFINE_PRIME4v (lime_gl_buffer_sub_data);
    DEFINE_PRIME1 (lime_gl_check_framebuffer_status);
    DEFINE_PRIME1v (lime_gl_clear);
    DEFINE_PRIME4v (lime_gl_clear_bufferfi);
    DEFINE_PRIME3v (lime_gl_clear_bufferfv);
    DEFINE_PRIME3v (lime_gl_clear_bufferiv);
    DEFINE_PRIME3v (lime_gl_clear_bufferuiv);
    DEFINE_PRIME4v (lime_gl_clear_color);
    DEFINE_PRIME1v (lime_gl_clear_depthf);
    DEFINE_PRIME1v (lime_gl_clear_stencil);
    DEFINE_PRIME4 (lime_gl_client_wait_sync);
    DEFINE_PRIME4v (lime_gl_color_mask);
    DEFINE_PRIME1v (lime_gl_compile_shader);
    DEFINE_PRIME8v (lime_gl_compressed_tex_image_2d);
    DEFINE_PRIME9v (lime_gl_compressed_tex_image_3d);
    DEFINE_PRIME9v (lime_gl_compressed_tex_sub_image_2d);
    DEFINE_PRIME11v (lime_gl_compressed_tex_sub_image_3d);
    DEFINE_PRIME5v (lime_gl_copy_buffer_sub_data);
    DEFINE_PRIME8v (lime_gl_copy_tex_image_2d);
    DEFINE_PRIME8v (lime_gl_copy_tex_sub_image_2d);
    DEFINE_PRIME9v (lime_gl_copy_tex_sub_image_3d);
    DEFINE_PRIME0 (lime_gl_create_buffer);
    DEFINE_PRIME0 (lime_gl_create_framebuffer);
    DEFINE_PRIME0 (lime_gl_create_program);
    DEFINE_PRIME0 (lime_gl_create_query);
    DEFINE_PRIME0 (lime_gl_create_renderbuffer);
    DEFINE_PRIME0 (lime_gl_create_sampler);
    DEFINE_PRIME1 (lime_gl_create_shader);
    DEFINE_PRIME0 (lime_gl_create_texture);
    DEFINE_PRIME0 (lime_gl_create_transform_feedback);
    DEFINE_PRIME0 (lime_gl_create_vertex_array);
    DEFINE_PRIME1v (lime_gl_cull_face);
    DEFINE_PRIME1v (lime_gl_delete_buffer);
    DEFINE_PRIME1v (lime_gl_delete_framebuffer);
    DEFINE_PRIME1v (lime_gl_delete_program);
    DEFINE_PRIME1v (lime_gl_delete_query);
    DEFINE_PRIME1v (lime_gl_delete_renderbuffer);
    DEFINE_PRIME1v (lime_gl_delete_sampler);
    DEFINE_PRIME1v (lime_gl_delete_shader);
    DEFINE_PRIME1v (lime_gl_delete_sync);
    DEFINE_PRIME1v (lime_gl_delete_texture);
    DEFINE_PRIME1v (lime_gl_delete_transform_feedback);
    DEFINE_PRIME1v (lime_gl_delete_vertex_array);
    DEFINE_PRIME1v (lime_gl_depth_func);
    DEFINE_PRIME1v (lime_gl_depth_mask);
    DEFINE_PRIME2v (lime_gl_depth_rangef);
    DEFINE_PRIME2v (lime_gl_detach_shader);
    DEFINE_PRIME1v (lime_gl_disable);
    DEFINE_PRIME1v (lime_gl_disable_vertex_attrib_array);
    DEFINE_PRIME3v (lime_gl_draw_arrays);
    DEFINE_PRIME4v (lime_gl_draw_arrays_instanced);
    DEFINE_PRIME1v (lime_gl_draw_buffers);
    DEFINE_PRIME4v (lime_gl_draw_elements);
    DEFINE_PRIME5v (lime_gl_draw_elements_instanced);
    DEFINE_PRIME6v (lime_gl_draw_range_elements);
    DEFINE_PRIME1v (lime_gl_enable);
    DEFINE_PRIME1v (lime_gl_enable_vertex_attrib_array);
    DEFINE_PRIME1v (lime_gl_end_query);
    DEFINE_PRIME0v (lime_gl_end_transform_feedback);
    DEFINE_PRIME2 (lime_gl_fence_sync);
    DEFINE_PRIME0v (lime_gl_finish);
    DEFINE_PRIME0v (lime_gl_flush);
    DEFINE_PRIME4v (lime_gl_framebuffer_renderbuffer);
    DEFINE_PRIME5v (lime_gl_framebuffer_texture_layer);
    DEFINE_PRIME5v (lime_gl_framebuffer_texture2D);
    DEFINE_PRIME1v (lime_gl_front_face);
    DEFINE_PRIME1v (lime_gl_generate_mipmap);
    DEFINE_PRIME2 (lime_gl_get_active_attrib);
    DEFINE_PRIME2 (lime_gl_get_active_uniform);
    DEFINE_PRIME3 (lime_gl_get_active_uniform_blocki);
    DEFINE_PRIME4v (lime_gl_get_active_uniform_blockiv);
    DEFINE_PRIME2 (lime_gl_get_active_uniform_block_name);
    DEFINE_PRIME4v (lime_gl_get_active_uniformsiv);
    DEFINE_PRIME1 (lime_gl_get_attached_shaders);
    DEFINE_PRIME2 (lime_gl_get_attrib_location);
    DEFINE_PRIME1 (lime_gl_get_boolean);
    DEFINE_PRIME2v (lime_gl_get_booleanv);
    DEFINE_PRIME2 (lime_gl_get_buffer_parameteri);
    DEFINE_PRIME3v (lime_gl_get_buffer_parameteriv);
    DEFINE_PRIME3v (lime_gl_get_buffer_parameteri64v);
    DEFINE_PRIME2 (lime_gl_get_buffer_pointerv);
    DEFINE_PRIME4v (lime_gl_get_buffer_sub_data);
    DEFINE_PRIME0 (lime_gl_get_context_attributes);
    DEFINE_PRIME0 (lime_gl_get_error);
    DEFINE_PRIME1 (lime_gl_get_extension);
    DEFINE_PRIME1 (lime_gl_get_float);
    DEFINE_PRIME2v (lime_gl_get_floatv);
    DEFINE_PRIME2 (lime_gl_get_frag_data_location);
    DEFINE_PRIME3 (lime_gl_get_framebuffer_attachment_parameteri);
    DEFINE_PRIME4v (lime_gl_get_framebuffer_attachment_parameteriv);
    DEFINE_PRIME1 (lime_gl_get_integer);
    DEFINE_PRIME2v (lime_gl_get_integerv);
    DEFINE_PRIME2v (lime_gl_get_integer64v);
    DEFINE_PRIME3v (lime_gl_get_integer64i_v);
    DEFINE_PRIME3v (lime_gl_get_integeri_v);
    DEFINE_PRIME5v (lime_gl_get_internalformativ);
    DEFINE_PRIME2 (lime_gl_get_programi);
    DEFINE_PRIME3v (lime_gl_get_programiv);
    DEFINE_PRIME3v (lime_gl_get_program_binary);
    DEFINE_PRIME1 (lime_gl_get_program_info_log);
    DEFINE_PRIME2 (lime_gl_get_queryi);
    DEFINE_PRIME3v (lime_gl_get_queryiv);
    DEFINE_PRIME2 (lime_gl_get_query_objectui);
    DEFINE_PRIME3v (lime_gl_get_query_objectuiv);
    DEFINE_PRIME2 (lime_gl_get_renderbuffer_parameteri);
    DEFINE_PRIME3v (lime_gl_get_renderbuffer_parameteriv);
    DEFINE_PRIME2 (lime_gl_get_sampler_parameterf);
    DEFINE_PRIME3v (lime_gl_get_sampler_parameterfv);
    DEFINE_PRIME2 (lime_gl_get_sampler_parameteri);
    DEFINE_PRIME3v (lime_gl_get_sampler_parameteriv);
    DEFINE_PRIME1 (lime_gl_get_shader_info_log);
    DEFINE_PRIME2 (lime_gl_get_shaderi);
    DEFINE_PRIME3v (lime_gl_get_shaderiv);
    DEFINE_PRIME2 (lime_gl_get_shader_precision_format);
    DEFINE_PRIME1 (lime_gl_get_shader_source);
    DEFINE_PRIME1 (lime_gl_get_string);
    DEFINE_PRIME2 (lime_gl_get_stringi);
    DEFINE_PRIME2 (lime_gl_get_sync_parameteri);
    DEFINE_PRIME3v (lime_gl_get_sync_parameteriv);
    DEFINE_PRIME2 (lime_gl_get_tex_parameterf);
    DEFINE_PRIME3v (lime_gl_get_tex_parameterfv);
    DEFINE_PRIME2 (lime_gl_get_tex_parameteri);
    DEFINE_PRIME3v (lime_gl_get_tex_parameteriv);
    DEFINE_PRIME2 (lime_gl_get_transform_feedback_varying);
    DEFINE_PRIME2 (lime_gl_get_uniformf);
    DEFINE_PRIME3v (lime_gl_get_uniformfv);
    DEFINE_PRIME2 (lime_gl_get_uniformi);
    DEFINE_PRIME3v (lime_gl_get_uniformiv);
    DEFINE_PRIME2 (lime_gl_get_uniformui);
    DEFINE_PRIME3v (lime_gl_get_uniformuiv);
    DEFINE_PRIME2 (lime_gl_get_uniform_block_index);
    DEFINE_PRIME2 (lime_gl_get_uniform_location);
    DEFINE_PRIME2 (lime_gl_get_vertex_attribf);
    DEFINE_PRIME3v (lime_gl_get_vertex_attribfv);
    DEFINE_PRIME2 (lime_gl_get_vertex_attribi);
    DEFINE_PRIME3v (lime_gl_get_vertex_attribiv);
    DEFINE_PRIME2 (lime_gl_get_vertex_attribii);
    DEFINE_PRIME3v (lime_gl_get_vertex_attribiiv);
    DEFINE_PRIME2 (lime_gl_get_vertex_attribiui);
    DEFINE_PRIME3v (lime_gl_get_vertex_attribiuiv);
    DEFINE_PRIME2 (lime_gl_get_vertex_attrib_pointerv);
    DEFINE_PRIME2v (lime_gl_hint);
    DEFINE_PRIME2v (lime_gl_invalidate_framebuffer);
    DEFINE_PRIME6v (lime_gl_invalidate_sub_framebuffer);
    DEFINE_PRIME1 (lime_gl_is_buffer);
    DEFINE_PRIME1 (lime_gl_is_enabled);
    DEFINE_PRIME1 (lime_gl_is_framebuffer);
    DEFINE_PRIME1 (lime_gl_is_program);
    DEFINE_PRIME1 (lime_gl_is_query);
    DEFINE_PRIME1 (lime_gl_is_renderbuffer);
    DEFINE_PRIME1 (lime_gl_is_sampler);
    DEFINE_PRIME1 (lime_gl_is_shader);
    DEFINE_PRIME1 (lime_gl_is_sync);
    DEFINE_PRIME1 (lime_gl_is_texture);
    DEFINE_PRIME1 (lime_gl_is_transform_feedback);
    DEFINE_PRIME1 (lime_gl_is_vertex_array);
    DEFINE_PRIME1v (lime_gl_line_width);
    DEFINE_PRIME1v (lime_gl_link_program);
    DEFINE_PRIME4 (lime_gl_map_buffer_range);
    DEFINE_PRIME1v (lime_gl_object_deregister);
    DEFINE_PRIME2 (lime_gl_object_from_id);
    DEFINE_PRIME3 (lime_gl_object_register);
    DEFINE_PRIME0v (lime_gl_pause_transform_feedback);
    DEFINE_PRIME2v (lime_gl_pixel_storei);
    DEFINE_PRIME2v (lime_gl_polygon_offset);
    DEFINE_PRIME4v (lime_gl_program_binary);
    DEFINE_PRIME3v (lime_gl_program_parameteri);
    DEFINE_PRIME1v (lime_gl_read_buffer);
    DEFINE_PRIME7v (lime_gl_read_pixels);
    DEFINE_PRIME0v (lime_gl_release_shader_compiler);
    DEFINE_PRIME4v (lime_gl_renderbuffer_storage);
    DEFINE_PRIME5v (lime_gl_renderbuffer_storage_multisample);
    DEFINE_PRIME0v (lime_gl_resume_transform_feedback);
    DEFINE_PRIME2v (lime_gl_sample_coverage);
    DEFINE_PRIME3v (lime_gl_sampler_parameterf);
    DEFINE_PRIME3v (lime_gl_sampler_parameteri);
    DEFINE_PRIME4v (lime_gl_scissor);
    DEFINE_PRIME4v (lime_gl_shader_binary);
    DEFINE_PRIME2v (lime_gl_shader_source);
    DEFINE_PRIME3v (lime_gl_stencil_func);
    DEFINE_PRIME4v (lime_gl_stencil_func_separate);
    DEFINE_PRIME1v (lime_gl_stencil_mask);
    DEFINE_PRIME2v (lime_gl_stencil_mask_separate);
    DEFINE_PRIME3v (lime_gl_stencil_op);
    DEFINE_PRIME4v (lime_gl_stencil_op_separate);
    DEFINE_PRIME9v (lime_gl_tex_image_2d);
    DEFINE_PRIME10v (lime_gl_tex_image_3d);
    DEFINE_PRIME3v (lime_gl_tex_parameterf);
    DEFINE_PRIME3v (lime_gl_tex_parameteri);
    DEFINE_PRIME5v (lime_gl_tex_storage_2d);
    DEFINE_PRIME6v (lime_gl_tex_storage_3d);
    DEFINE_PRIME9v (lime_gl_tex_sub_image_2d);
    DEFINE_PRIME11v (lime_gl_tex_sub_image_3d);
    DEFINE_PRIME3v (lime_gl_transform_feedback_varyings);
    DEFINE_PRIME2v (lime_gl_uniform1f);
    DEFINE_PRIME3v (lime_gl_uniform1fv);
    DEFINE_PRIME2v (lime_gl_uniform1i);
    DEFINE_PRIME3v (lime_gl_uniform1iv);
    DEFINE_PRIME2v (lime_gl_uniform1ui);
    DEFINE_PRIME3v (lime_gl_uniform1uiv);
    DEFINE_PRIME3v (lime_gl_uniform2f);
    DEFINE_PRIME3v (lime_gl_uniform2fv);
    DEFINE_PRIME3v (lime_gl_uniform2i);
    DEFINE_PRIME3v (lime_gl_uniform2iv);
    DEFINE_PRIME3v (lime_gl_uniform2ui);
    DEFINE_PRIME3v (lime_gl_uniform2uiv);
    DEFINE_PRIME4v (lime_gl_uniform3f);
    DEFINE_PRIME3v (lime_gl_uniform3fv);
    DEFINE_PRIME4v (lime_gl_uniform3i);
    DEFINE_PRIME3v (lime_gl_uniform3iv);
    DEFINE_PRIME4v (lime_gl_uniform3ui);
    DEFINE_PRIME3v (lime_gl_uniform3uiv);
    DEFINE_PRIME5v (lime_gl_uniform4f);
    DEFINE_PRIME3v (lime_gl_uniform4fv);
    DEFINE_PRIME5v (lime_gl_uniform4i);
    DEFINE_PRIME3v (lime_gl_uniform4iv);
    DEFINE_PRIME5v (lime_gl_uniform4ui);
    DEFINE_PRIME3v (lime_gl_uniform4uiv);
    DEFINE_PRIME3v (lime_gl_uniform_block_binding);
    DEFINE_PRIME4v (lime_gl_uniform_matrix2fv);
    DEFINE_PRIME4v (lime_gl_uniform_matrix2x3fv);
    DEFINE_PRIME4v (lime_gl_uniform_matrix2x4fv);
    DEFINE_PRIME4v (lime_gl_uniform_matrix3fv);
    DEFINE_PRIME4v (lime_gl_uniform_matrix3x2fv);
    DEFINE_PRIME4v (lime_gl_uniform_matrix3x4fv);
    DEFINE_PRIME4v (lime_gl_uniform_matrix4fv);
    DEFINE_PRIME4v (lime_gl_uniform_matrix4x2fv);
    DEFINE_PRIME4v (lime_gl_uniform_matrix4x3fv);
    DEFINE_PRIME1 (lime_gl_unmap_buffer);
    DEFINE_PRIME1v (lime_gl_use_program);
    DEFINE_PRIME1v (lime_gl_validate_program);
    DEFINE_PRIME2v (lime_gl_vertex_attrib_divisor);
    DEFINE_PRIME5v (lime_gl_vertex_attrib_ipointer);
    DEFINE_PRIME6v (lime_gl_vertex_attrib_pointer);
    DEFINE_PRIME5v (lime_gl_vertex_attribi4i);
    DEFINE_PRIME2v (lime_gl_vertex_attribi4iv);
    DEFINE_PRIME5v (lime_gl_vertex_attribi4ui);
    DEFINE_PRIME2v (lime_gl_vertex_attribi4uiv);
    DEFINE_PRIME2v (lime_gl_vertex_attrib1f);
    DEFINE_PRIME2v (lime_gl_vertex_attrib1fv);
    DEFINE_PRIME3v (lime_gl_vertex_attrib2f);
    DEFINE_PRIME2v (lime_gl_vertex_attrib2fv);
    DEFINE_PRIME4v (lime_gl_vertex_attrib3f);
    DEFINE_PRIME2v (lime_gl_vertex_attrib3fv);
    DEFINE_PRIME5v (lime_gl_vertex_attrib4f);
    DEFINE_PRIME2v (lime_gl_vertex_attrib4fv);
    DEFINE_PRIME4v (lime_gl_viewport);
    DEFINE_PRIME4v (lime_gl_wait_sync);

}