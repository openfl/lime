#include <hx/CFFI.h>

#ifdef NME_SDL2
#include <SDL.h>
#endif

#ifdef HX_WINDOWS
#include <SDL_syswm.h>
#include <Windows.h>
#endif


// Custom DEFINE_PRIM macro when calls are the same as NME

#ifdef STATIC_LINK

#define DEFINE_LIME_LEGACY_PRIM_MULT(func) value nme_##func(value *arg, int args); \
int __reg_lime_legacy_##func = hx_register_prim("lime_legacy_" #func "__MULT",(void *)(&nme_##func)); \

#define DEFINE_LIME_LEGACY_PRIM(func,nargs) \
int __reg_lime_legacy_##func = hx_register_prim("lime_legacy_" #func "__" #nargs,(void *)(&nme_##func)); \

#define DEFINE_LIME_LEGACY_PRIM_MULT_NATIVE(func,ext) \
int __reg_lime_legacy_##func = hx_register_prim("lime_legacy_" #func "__" MULT,(void *)(&nme_##func)) + \
                   hx_register_prim("lime_legacy_" #func "__" #ext,(void *)(&nme_##func##_##ext)) ; 

#define DEFINE_LIME_LEGACY_PRIM_NATIVE(func,nargs,ext) \
int __reg_lime_legacy_##func = hx_register_prim("lime_legacy_" #func "__" #nargs,(void *)(&nme_##func)) + \
                   hx_register_prim("lime_legacy_" #func "__" #ext,(void *)(&nme_##func##_##ext)) ; 

#else

#define DEFINE_LIME_LEGACY_PRIM_MULT(func) value nme_##func(value *arg, int args); \
extern "C" { \
  EXPORT void *lime_legacy_##func##__MULT() { return (void*)(&nme_##func); } \
}

#define DEFINE_LIME_LEGACY_PRIM(func,nargs) extern "C" { \
  EXPORT void *lime_legacy_##func##__##nargs() { return (void*)(&nme_##func); } \
}

#define DEFINE_LIME_LEGACY_PRIM_MULT_NATIVE(func,ext) extern "C" { \
  EXPORT void *lime_legacy_##func##__MULT() { return (void*)(&nme_##func); } \
  EXPORT void *lime_legacy_##func##__##ext() { return (void*)(&nme_##func##_##ext); } \
}

#define DEFINE_LIME_LEGACY_PRIM_NATIVE(func,nargs,ext) extern "C" { \
  EXPORT void *lime_legacy_##func##__##nargs() { return (void*)(&nme_##func); } \
  EXPORT void *lime_legacy_##func##__##ext() { return (void*)(&nme_##func##_##ext); } \
}

#endif


// Forward declare common CFFI calls, and expose to Haxe

#define DEFINE_LIME_LEGACY_PRIM_0(func) value nme_##func(); \
  DEFINE_LIME_LEGACY_PRIM(func,0)

#define DEFINE_LIME_LEGACY_PRIM_1(func) value nme_##func(value p1); \
  DEFINE_LIME_LEGACY_PRIM(func,1)

#define DEFINE_LIME_LEGACY_PRIM_2(func) value nme_##func(value p1, value p2); \
  DEFINE_LIME_LEGACY_PRIM(func,2)

#define DEFINE_LIME_LEGACY_PRIM_3(func) value nme_##func(value p1, value p2, value p3); \
  DEFINE_LIME_LEGACY_PRIM(func,3)

#define DEFINE_LIME_LEGACY_PRIM_4(func) value nme_##func(value p1, value p2, value p3, value p4); \
  DEFINE_LIME_LEGACY_PRIM(func,4)

#define DEFINE_LIME_LEGACY_PRIM_5(func) value nme_##func(value p1, value p2, value p3, value p4, value p5); \
  DEFINE_LIME_LEGACY_PRIM(func,5)

#define DEFINE_LIME_LEGACY_PRIM_6(func) value nme_##func(value p1, value p2, value p3, value p4, value p5, value p6); \
  DEFINE_LIME_LEGACY_PRIM(func,6)

#define DEFINE_LIME_PROP_READ(obj,prop) DEFINE_LIME_LEGACY_PRIM_1(obj##_get_##prop)

#define DEFINE_LIME_PROP(obj,prop) DEFINE_LIME_LEGACY_PRIM_1(obj##_get_##prop) \
  DEFINE_LIME_LEGACY_PRIM_2(obj##_set_##prop)


// Define common CFFI NME calls

#ifdef ANDROID
DEFINE_LIME_LEGACY_PRIM_1(jni_init_callback);
DEFINE_LIME_LEGACY_PRIM_4(jni_create_field);
DEFINE_LIME_LEGACY_PRIM_1(jni_get_static);
DEFINE_LIME_LEGACY_PRIM_2(jni_set_static);
DEFINE_LIME_LEGACY_PRIM_2(jni_get_member);
DEFINE_LIME_LEGACY_PRIM_3(jni_set_member);
DEFINE_LIME_LEGACY_PRIM_5(jni_create_method);
DEFINE_LIME_LEGACY_PRIM_2(jni_call_static);
DEFINE_LIME_LEGACY_PRIM_3(jni_call_member);
DEFINE_LIME_LEGACY_PRIM_0(jni_get_env);
DEFINE_LIME_LEGACY_PRIM_1(jni_get_jobject);
DEFINE_LIME_LEGACY_PRIM_1(post_ui_callback);
#endif
DEFINE_LIME_LEGACY_PRIM_0(time_stamp);
DEFINE_LIME_LEGACY_PRIM_1(error_output);
DEFINE_LIME_LEGACY_PRIM_0(get_ndll_version);
DEFINE_LIME_LEGACY_PRIM_0(get_nme_state_version);
DEFINE_LIME_LEGACY_PRIM_0(get_bits);
DEFINE_LIME_LEGACY_PRIM_4(byte_array_init);
DEFINE_LIME_LEGACY_PRIM_2(byte_array_overwrite_file);
DEFINE_LIME_LEGACY_PRIM_1(byte_array_read_file);
DEFINE_LIME_LEGACY_PRIM_1(byte_array_get_native_pointer);
DEFINE_LIME_LEGACY_PRIM_2(weak_ref_create);
DEFINE_LIME_LEGACY_PRIM_1(weak_ref_get);
DEFINE_LIME_LEGACY_PRIM_0(get_unique_device_identifier);
DEFINE_LIME_LEGACY_PRIM_1(set_icon);
DEFINE_LIME_LEGACY_PRIM_0(sys_get_exe_name);
DEFINE_LIME_LEGACY_PRIM_0(capabilities_get_screen_resolutions);
DEFINE_LIME_LEGACY_PRIM_0(capabilities_get_screen_modes);
DEFINE_LIME_LEGACY_PRIM_0(capabilities_get_pixel_aspect_ratio);
DEFINE_LIME_LEGACY_PRIM_0(capabilities_get_screen_dpi);
DEFINE_LIME_LEGACY_PRIM_0(capabilities_get_screen_resolution_x);
DEFINE_LIME_LEGACY_PRIM_0(capabilities_get_screen_resolution_y);
DEFINE_LIME_LEGACY_PRIM_0(capabilities_get_language);
DEFINE_LIME_LEGACY_PRIM_0(get_resource_path);
DEFINE_LIME_LEGACY_PRIM_1(filesystem_get_special_dir);
DEFINE_LIME_LEGACY_PRIM_2(filesystem_get_volumes);
DEFINE_LIME_LEGACY_PRIM_1(get_url);
DEFINE_LIME_LEGACY_PRIM_2(haptic_vibrate);
DEFINE_LIME_LEGACY_PRIM_2(set_user_preference);
DEFINE_LIME_LEGACY_PRIM_1(get_user_preference);
DEFINE_LIME_LEGACY_PRIM_1(clear_user_preference);
DEFINE_LIME_LEGACY_PRIM_1(stage_set_fixed_orientation);
//DEFINE_LIME_LEGACY_PRIM_0(init_sdl_audio);
DEFINE_LIME_LEGACY_PRIM_1(get_frame_stage);
DEFINE_LIME_LEGACY_PRIM_4(set_package);
DEFINE_LIME_LEGACY_PRIM_MULT(create_main_frame);
DEFINE_LIME_LEGACY_PRIM_1(set_asset_base);
DEFINE_LIME_LEGACY_PRIM_0(terminate);
DEFINE_LIME_LEGACY_PRIM_0(close);
DEFINE_LIME_LEGACY_PRIM_0(start_animation);
DEFINE_LIME_LEGACY_PRIM_0(pause_animation);
DEFINE_LIME_LEGACY_PRIM_0(resume_animation);
DEFINE_LIME_LEGACY_PRIM_0(stop_animation);
DEFINE_LIME_LEGACY_PRIM_2(stage_set_next_wake);
DEFINE_LIME_LEGACY_PRIM_4(set_stage_handler);
DEFINE_LIME_LEGACY_PRIM_1(render_stage);
DEFINE_LIME_LEGACY_PRIM_1(set_render_gc_free);
DEFINE_LIME_LEGACY_PRIM_3(stage_resize_window);
DEFINE_LIME_LEGACY_PRIM_3(stage_set_resolution);
DEFINE_LIME_LEGACY_PRIM_5(stage_set_screenmode);
DEFINE_LIME_LEGACY_PRIM_2(stage_set_fullscreen);
DEFINE_LIME_LEGACY_PRIM_1(stage_get_focus_id);
DEFINE_LIME_LEGACY_PRIM_3(stage_set_focus);
DEFINE_LIME_LEGACY_PRIM_2(stage_get_joystick_name);
DEFINE_LIME_LEGACY_PRIM_1(stage_is_opengl);
DEFINE_LIME_LEGACY_PRIM_0(stage_request_render);
DEFINE_LIME_LEGACY_PRIM_2(stage_show_cursor);
DEFINE_LIME_LEGACY_PRIM_2(stage_constrain_cursor_to_window_frame);
DEFINE_LIME_LEGACY_PRIM_3(stage_set_cursor_position_in_window);
DEFINE_LIME_LEGACY_PRIM_3(stage_set_window_position);
DEFINE_LIME_LEGACY_PRIM_0(stage_get_orientation);
DEFINE_LIME_LEGACY_PRIM_0(stage_get_normal_orientation);
DEFINE_LIME_PROP(stage,focus_rect);
DEFINE_LIME_PROP(stage,scale_mode);
#ifdef NME_S3D
DEFINE_LIME_PROP(stage,autos3d);
#else
value nme_stage_get_autos3d(value inHandle) { return alloc_bool(false); }
value nme_stage_set_autos3d(value inHandle, value inVal) { return inVal; }
DEFINE_LIME_LEGACY_PRIM(stage_get_autos3d,1);
DEFINE_LIME_LEGACY_PRIM(stage_set_autos3d,2);
#endif
DEFINE_LIME_PROP(stage,align);
DEFINE_LIME_PROP(stage,quality);
DEFINE_LIME_PROP(stage,display_state);
DEFINE_LIME_PROP(stage,multitouch_active);
DEFINE_LIME_PROP_READ(stage,keyboard_height);
DEFINE_LIME_PROP_READ(stage,stage_width);
DEFINE_LIME_PROP_READ(stage,stage_height);
DEFINE_LIME_PROP_READ(stage,dpi_scale);
DEFINE_LIME_PROP_READ(stage,multitouch_supported);
DEFINE_LIME_LEGACY_PRIM_2(sv_create);
DEFINE_LIME_LEGACY_PRIM_1(sv_destroy);
DEFINE_LIME_LEGACY_PRIM_2(sv_action);
DEFINE_LIME_LEGACY_PRIM_4(sv_play);
DEFINE_LIME_LEGACY_PRIM_2(sv_seek);
DEFINE_LIME_LEGACY_PRIM_1(sv_get_time);
DEFINE_LIME_LEGACY_PRIM_5(sv_viewport);
DEFINE_LIME_LEGACY_PRIM_3(sv_pan);
DEFINE_LIME_LEGACY_PRIM_3(sv_zoom);
DEFINE_LIME_LEGACY_PRIM_3(sv_set_sound_transform);
DEFINE_LIME_LEGACY_PRIM_1(sv_get_buffered_percent);
DEFINE_LIME_LEGACY_PRIM_3(managed_stage_create);
DEFINE_LIME_LEGACY_PRIM_2(managed_stage_pump_event);
DEFINE_LIME_LEGACY_PRIM_0(input_get_acceleration);
DEFINE_LIME_LEGACY_PRIM_0(create_display_object);
DEFINE_LIME_LEGACY_PRIM_1(display_object_get_graphics);
DEFINE_LIME_LEGACY_PRIM_MULT(display_object_draw_to_surface);
DEFINE_LIME_LEGACY_PRIM_1(display_object_get_id);
DEFINE_LIME_LEGACY_PRIM_2(display_object_global_to_local);
DEFINE_LIME_LEGACY_PRIM_1(type);
DEFINE_LIME_LEGACY_PRIM_2(display_object_local_to_global);
DEFINE_LIME_LEGACY_PRIM_5(display_object_hit_test_point);
DEFINE_LIME_LEGACY_PRIM_2(display_object_set_filters);
DEFINE_LIME_LEGACY_PRIM_2(display_object_set_scale9_grid);
DEFINE_LIME_LEGACY_PRIM_2(display_object_set_scroll_rect);
DEFINE_LIME_LEGACY_PRIM_2(display_object_set_mask);
DEFINE_LIME_LEGACY_PRIM_2(display_object_set_matrix);
DEFINE_LIME_LEGACY_PRIM_3(display_object_get_matrix);
DEFINE_LIME_LEGACY_PRIM_2(display_object_set_color_transform);
DEFINE_LIME_LEGACY_PRIM_3(display_object_get_color_transform);
DEFINE_LIME_LEGACY_PRIM_2(display_object_get_pixel_bounds);
DEFINE_LIME_LEGACY_PRIM_4(display_object_get_bounds);
DEFINE_LIME_LEGACY_PRIM_1(display_object_request_soft_keyboard);
DEFINE_LIME_LEGACY_PRIM_1(display_object_dismiss_soft_keyboard);
DEFINE_LIME_PROP(display_object,x);
DEFINE_LIME_PROP(display_object,y);
#ifdef NME_S3D
DEFINE_LIME_PROP(display_object,z);
#else
value nme_display_object_get_z(value inHandle) { return alloc_int(0); }
value nme_display_object_set_z(value inHandle, value inVal) { return inVal; }
DEFINE_LIME_LEGACY_PRIM(display_object_get_z,1);
DEFINE_LIME_LEGACY_PRIM(display_object_set_z,2);
#endif
DEFINE_LIME_PROP(display_object,scale_x);
DEFINE_LIME_PROP(display_object,scale_y);
DEFINE_LIME_PROP(display_object,rotation);
DEFINE_LIME_PROP(display_object,width);
DEFINE_LIME_PROP(display_object,height);
DEFINE_LIME_PROP(display_object,alpha);
DEFINE_LIME_PROP(display_object,bg);
DEFINE_LIME_PROP(display_object,mouse_enabled);
DEFINE_LIME_PROP(display_object,cache_as_bitmap);
DEFINE_LIME_PROP(display_object,pedantic_bitmap_caching);
DEFINE_LIME_PROP(display_object,pixel_snapping);
DEFINE_LIME_PROP(display_object,visible);
DEFINE_LIME_PROP(display_object,name);
DEFINE_LIME_PROP(display_object,blend_mode);
DEFINE_LIME_PROP(display_object,needs_soft_keyboard);
DEFINE_LIME_PROP(display_object,moves_for_soft_keyboard);
DEFINE_LIME_PROP_READ(display_object,mouse_x);
DEFINE_LIME_PROP_READ(display_object,mouse_y);
DEFINE_LIME_LEGACY_PRIM_0(direct_renderer_create);
DEFINE_LIME_LEGACY_PRIM_2(direct_renderer_set);
DEFINE_LIME_LEGACY_PRIM_0(simple_button_create);
DEFINE_LIME_LEGACY_PRIM_3(simple_button_set_state);
DEFINE_LIME_PROP(simple_button,enabled);
DEFINE_LIME_PROP(simple_button,hand_cursor);
DEFINE_LIME_LEGACY_PRIM_0(create_display_object_container);
DEFINE_LIME_LEGACY_PRIM_2(doc_add_child);
DEFINE_LIME_LEGACY_PRIM_3(doc_swap_children);
DEFINE_LIME_LEGACY_PRIM_2(doc_remove_child);
DEFINE_LIME_LEGACY_PRIM_3(doc_set_child_index);
DEFINE_LIME_PROP(doc,mouse_children);
DEFINE_LIME_LEGACY_PRIM_2(external_interface_add_callback);
DEFINE_LIME_LEGACY_PRIM_0(external_interface_available);
DEFINE_LIME_LEGACY_PRIM_2(external_interface_call);
DEFINE_LIME_LEGACY_PRIM_0(external_interface_register_callbacks);
DEFINE_LIME_LEGACY_PRIM_1(gfx_clear);
DEFINE_LIME_LEGACY_PRIM_3(gfx_begin_fill);
DEFINE_LIME_LEGACY_PRIM_5(gfx_begin_bitmap_fill);
DEFINE_LIME_LEGACY_PRIM_5(gfx_line_bitmap_fill);
DEFINE_LIME_LEGACY_PRIM_MULT(gfx_begin_gradient_fill);
DEFINE_LIME_LEGACY_PRIM_MULT(gfx_line_gradient_fill);
DEFINE_LIME_LEGACY_PRIM_1(gfx_end_fill);
DEFINE_LIME_LEGACY_PRIM_MULT(gfx_line_style);
DEFINE_LIME_LEGACY_PRIM_3(gfx_move_to);
DEFINE_LIME_LEGACY_PRIM_3(gfx_line_to);
DEFINE_LIME_LEGACY_PRIM_5(gfx_curve_to);
DEFINE_LIME_LEGACY_PRIM_5(gfx_arc_to);
DEFINE_LIME_LEGACY_PRIM_5(gfx_draw_ellipse);
DEFINE_LIME_LEGACY_PRIM_5(gfx_draw_rect);
DEFINE_LIME_LEGACY_PRIM_4(gfx_draw_path);
DEFINE_LIME_LEGACY_PRIM_MULT(gfx_draw_round_rect);
DEFINE_LIME_LEGACY_PRIM_MULT(gfx_draw_triangles);
DEFINE_LIME_LEGACY_PRIM_2(gfx_draw_data);
DEFINE_LIME_LEGACY_PRIM_2(gfx_draw_datum);
DEFINE_LIME_LEGACY_PRIM_5(gfx_draw_tiles);
DEFINE_LIME_LEGACY_PRIM_MULT(gfx_draw_points);
DEFINE_LIME_LEGACY_PRIM_3(graphics_path_create);
DEFINE_LIME_LEGACY_PRIM_5(graphics_path_curve_to);
DEFINE_LIME_LEGACY_PRIM_3(graphics_path_line_to);
DEFINE_LIME_LEGACY_PRIM_3(graphics_path_move_to);
DEFINE_LIME_LEGACY_PRIM_3(graphics_path_wline_to);
DEFINE_LIME_LEGACY_PRIM_3(graphics_path_wmove_to);
DEFINE_LIME_LEGACY_PRIM_2(graphics_path_get_commands);
DEFINE_LIME_LEGACY_PRIM_2(graphics_path_set_commands);
DEFINE_LIME_LEGACY_PRIM_2(graphics_path_get_data);
DEFINE_LIME_LEGACY_PRIM_2(graphics_path_set_data);
DEFINE_LIME_LEGACY_PRIM_2(graphics_solid_fill_create);
DEFINE_LIME_LEGACY_PRIM_0(graphics_end_fill_create);
DEFINE_LIME_LEGACY_PRIM_MULT(graphics_stroke_create);
DEFINE_LIME_LEGACY_PRIM_0(text_field_create);
DEFINE_LIME_LEGACY_PRIM_2(text_field_set_def_text_format);
DEFINE_LIME_LEGACY_PRIM_4(text_field_get_text_format);
DEFINE_LIME_LEGACY_PRIM_4(text_field_set_text_format);
DEFINE_LIME_LEGACY_PRIM_2(text_field_get_def_text_format);
DEFINE_LIME_LEGACY_PRIM_3(text_field_get_line_metrics);
DEFINE_LIME_LEGACY_PRIM_2(text_field_get_line_text);
DEFINE_LIME_LEGACY_PRIM_2(text_field_get_line_offset);
DEFINE_LIME_PROP(text_field,text);
DEFINE_LIME_PROP(text_field,html_text);
DEFINE_LIME_PROP(text_field,text_color);
DEFINE_LIME_PROP(text_field,selectable);
DEFINE_LIME_PROP(text_field,display_as_password);
DEFINE_LIME_PROP(text_field,type);
DEFINE_LIME_PROP(text_field,multiline);
DEFINE_LIME_PROP(text_field,word_wrap);
DEFINE_LIME_PROP(text_field,background);
DEFINE_LIME_PROP(text_field,background_color);
DEFINE_LIME_PROP(text_field,border);
DEFINE_LIME_PROP(text_field,border_color);
DEFINE_LIME_PROP(text_field,embed_fonts);
DEFINE_LIME_PROP(text_field,auto_size);
DEFINE_LIME_PROP(text_field,scroll_h);
DEFINE_LIME_PROP(text_field,scroll_v);
DEFINE_LIME_PROP(text_field,max_chars);
DEFINE_LIME_PROP_READ(text_field,text_width);
DEFINE_LIME_PROP_READ(text_field,text_height);
DEFINE_LIME_PROP_READ(text_field,max_scroll_h);
DEFINE_LIME_PROP_READ(text_field,max_scroll_v);
DEFINE_LIME_PROP_READ(text_field,bottom_scroll_v);
DEFINE_LIME_PROP_READ(text_field,num_lines);
DEFINE_LIME_LEGACY_PRIM_MULT(bitmap_data_create);
DEFINE_LIME_LEGACY_PRIM_1(bitmap_data_width);
DEFINE_LIME_LEGACY_PRIM_1(bitmap_data_height);
DEFINE_LIME_LEGACY_PRIM_1(bitmap_data_get_prem_alpha);
DEFINE_LIME_LEGACY_PRIM_2(bitmap_data_set_prem_alpha);
DEFINE_LIME_LEGACY_PRIM_2(bitmap_data_clear);
DEFINE_LIME_LEGACY_PRIM_1(bitmap_data_get_transparent);
DEFINE_LIME_LEGACY_PRIM_2(bitmap_data_set_flags);
DEFINE_LIME_LEGACY_PRIM_4(bitmap_data_fill);
DEFINE_LIME_LEGACY_PRIM_2(bitmap_data_load);
DEFINE_LIME_LEGACY_PRIM_2(bitmap_data_set_format);
DEFINE_LIME_LEGACY_PRIM_2(bitmap_data_from_bytes);
DEFINE_LIME_LEGACY_PRIM_3(bitmap_data_encode);
DEFINE_LIME_LEGACY_PRIM_1(bitmap_data_clone);
DEFINE_LIME_LEGACY_PRIM_3(bitmap_data_color_transform);
DEFINE_LIME_LEGACY_PRIM_5(bitmap_data_apply_filter);
DEFINE_LIME_LEGACY_PRIM_5(bitmap_data_copy);
DEFINE_LIME_LEGACY_PRIM_MULT(bitmap_data_copy_channel);
DEFINE_LIME_LEGACY_PRIM_2(bitmap_data_get_pixels);
DEFINE_LIME_LEGACY_PRIM_3(bitmap_data_get_array);
DEFINE_LIME_LEGACY_PRIM_5(bitmap_data_get_color_bounds_rect);
DEFINE_LIME_LEGACY_PRIM_3(bitmap_data_get_pixel);
DEFINE_LIME_LEGACY_PRIM_3(bitmap_data_get_pixel32);
DEFINE_LIME_LEGACY_PRIM_3(bitmap_data_get_pixel_rgba);
DEFINE_LIME_LEGACY_PRIM_3(bitmap_data_scroll);
DEFINE_LIME_LEGACY_PRIM_4(bitmap_data_set_pixel);
DEFINE_LIME_LEGACY_PRIM_4(bitmap_data_set_pixel32);
DEFINE_LIME_LEGACY_PRIM_4(bitmap_data_set_pixel_rgba);
DEFINE_LIME_LEGACY_PRIM_4(bitmap_data_set_bytes);
DEFINE_LIME_LEGACY_PRIM_3(bitmap_data_set_array);
DEFINE_LIME_LEGACY_PRIM_3(bitmap_data_generate_filter_rect);
DEFINE_LIME_LEGACY_PRIM_MULT(bitmap_data_noise);
DEFINE_LIME_LEGACY_PRIM_4(bitmap_data_flood_fill);
DEFINE_LIME_LEGACY_PRIM_1(bitmap_data_unmultiply_alpha);
DEFINE_LIME_LEGACY_PRIM_1(bitmap_data_multiply_alpha);
DEFINE_LIME_LEGACY_PRIM_MULT(render_surface_to_surface);
DEFINE_LIME_LEGACY_PRIM_1(bitmap_data_dispose);
DEFINE_LIME_LEGACY_PRIM_1(bitmap_data_destroy_hardware_surface);
DEFINE_LIME_LEGACY_PRIM_1(bitmap_data_create_hardware_surface);
DEFINE_LIME_LEGACY_PRIM_1(bitmap_data_dump_bits);
DEFINE_LIME_LEGACY_PRIM_2(video_create);
DEFINE_LIME_LEGACY_PRIM_2(video_load);
DEFINE_LIME_LEGACY_PRIM_1(video_play);
DEFINE_LIME_LEGACY_PRIM_1(video_clear);
DEFINE_LIME_LEGACY_PRIM_2(video_set_smoothing);
DEFINE_LIME_LEGACY_PRIM_2(sound_from_file);
DEFINE_LIME_LEGACY_PRIM_3(sound_from_data);
DEFINE_LIME_LEGACY_PRIM_2(sound_get_id3);
DEFINE_LIME_LEGACY_PRIM_1(sound_get_length);
DEFINE_LIME_LEGACY_PRIM_1(sound_close);
DEFINE_LIME_LEGACY_PRIM_1(sound_get_status);
DEFINE_LIME_LEGACY_PRIM_1(sound_channel_is_complete);
DEFINE_LIME_LEGACY_PRIM_1(sound_channel_get_left);
DEFINE_LIME_LEGACY_PRIM_1(sound_channel_get_right);
DEFINE_LIME_LEGACY_PRIM_1(sound_channel_get_position);
DEFINE_LIME_LEGACY_PRIM_2(sound_channel_set_position);
DEFINE_LIME_LEGACY_PRIM_1(sound_channel_stop);
DEFINE_LIME_LEGACY_PRIM_2(sound_channel_set_transform);
DEFINE_LIME_LEGACY_PRIM_2(sound_channel_set_pitch);
DEFINE_LIME_LEGACY_PRIM_4(sound_channel_create);
DEFINE_LIME_LEGACY_PRIM_1(sound_channel_needs_data);
DEFINE_LIME_LEGACY_PRIM_2(sound_channel_add_data);
DEFINE_LIME_LEGACY_PRIM_1(sound_channel_get_data_position);
DEFINE_LIME_LEGACY_PRIM_2(sound_channel_create_dynamic);
DEFINE_LIME_LEGACY_PRIM_1(tilesheet_create);
DEFINE_LIME_LEGACY_PRIM_3(tilesheet_add_rect);
DEFINE_LIME_LEGACY_PRIM_1(curl_initialize);
DEFINE_LIME_LEGACY_PRIM_1(curl_create);
DEFINE_LIME_LEGACY_PRIM_0(curl_process_loaders);
DEFINE_LIME_LEGACY_PRIM_2(curl_update_loader);
DEFINE_LIME_LEGACY_PRIM_1(curl_get_error_message);
DEFINE_LIME_LEGACY_PRIM_1(curl_get_code);
DEFINE_LIME_LEGACY_PRIM_1(curl_get_data);
DEFINE_LIME_LEGACY_PRIM_1(curl_get_cookies);
DEFINE_LIME_LEGACY_PRIM_1(curl_get_headers);
DEFINE_LIME_LEGACY_PRIM_1(lzma_encode);
DEFINE_LIME_LEGACY_PRIM_1(lzma_decode);
DEFINE_LIME_LEGACY_PRIM_2(file_dialog_folder);
DEFINE_LIME_LEGACY_PRIM_3(file_dialog_open);
DEFINE_LIME_LEGACY_PRIM_3(file_dialog_save);
DEFINE_LIME_LEGACY_PRIM_1(font_iterate_device_fonts);


namespace nme {
	
	DEFINE_LIME_LEGACY_PRIM_1(font_set_factory);
	DEFINE_LIME_LEGACY_PRIM_2(font_register_font);
	DEFINE_LIME_LEGACY_PRIM_0(gl_get_error);
	DEFINE_LIME_LEGACY_PRIM_1(gl_get_extension);
	DEFINE_LIME_LEGACY_PRIM_0(gl_finish);
	DEFINE_LIME_LEGACY_PRIM_0(gl_flush);
	DEFINE_LIME_LEGACY_PRIM_0(gl_version);
	DEFINE_LIME_LEGACY_PRIM_1(gl_enable);
	DEFINE_LIME_LEGACY_PRIM_1(gl_disable);
	DEFINE_LIME_LEGACY_PRIM_2(gl_hint);
	DEFINE_LIME_LEGACY_PRIM_1(gl_line_width);
	DEFINE_LIME_LEGACY_PRIM_0(gl_get_context_attributes);
	DEFINE_LIME_LEGACY_PRIM_1(gl_get_supported_extensions);
	DEFINE_LIME_LEGACY_PRIM_1(gl_front_face);
	DEFINE_LIME_LEGACY_PRIM_1(gl_get_parameter);
	DEFINE_LIME_LEGACY_PRIM_1(gl_is_enabled);
	DEFINE_LIME_LEGACY_PRIM_0(gl_create_program);
	DEFINE_LIME_LEGACY_PRIM_1(gl_create_shader);
	DEFINE_LIME_LEGACY_PRIM_3(gl_stencil_func);
	DEFINE_LIME_LEGACY_PRIM_4(gl_stencil_func_separate);
	DEFINE_LIME_LEGACY_PRIM_1(gl_stencil_mask);
	DEFINE_LIME_LEGACY_PRIM_2(gl_stencil_mask_separate);
	DEFINE_LIME_LEGACY_PRIM_3(gl_stencil_op);
	DEFINE_LIME_LEGACY_PRIM_4(gl_stencil_op_separate);
	DEFINE_LIME_LEGACY_PRIM_4(gl_blend_color);
	DEFINE_LIME_LEGACY_PRIM_1(gl_blend_equation);
	DEFINE_LIME_LEGACY_PRIM_2(gl_blend_equation_separate);
	DEFINE_LIME_LEGACY_PRIM_2(gl_blend_func);
	DEFINE_LIME_LEGACY_PRIM_4(gl_blend_func_separate);
	DEFINE_LIME_LEGACY_PRIM_1(gl_link_program);
	DEFINE_LIME_LEGACY_PRIM_1(gl_validate_program);
	DEFINE_LIME_LEGACY_PRIM_1(gl_get_program_info_log);
	DEFINE_LIME_LEGACY_PRIM_3(gl_bind_attrib_location);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_attrib_location);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_uniform_location);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_uniform);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_program_parameter);
	DEFINE_LIME_LEGACY_PRIM_1(gl_use_program);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_active_attrib);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_active_uniform);
	DEFINE_LIME_LEGACY_PRIM_4(gl_uniform_matrix);
	DEFINE_LIME_LEGACY_PRIM_2(gl_uniform1iv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_uniform2iv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_uniform3iv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_uniform4iv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_uniform1fv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_uniform2fv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_uniform3fv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_uniform4fv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_vertex_attrib1f);
	DEFINE_LIME_LEGACY_PRIM_3(gl_vertex_attrib2f);
	DEFINE_LIME_LEGACY_PRIM_4(gl_vertex_attrib3f);
	DEFINE_LIME_LEGACY_PRIM_5(gl_vertex_attrib4f);
	DEFINE_LIME_LEGACY_PRIM_2(gl_vertex_attrib1fv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_vertex_attrib2fv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_vertex_attrib3fv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_vertex_attrib4fv);
	DEFINE_LIME_LEGACY_PRIM_2(gl_shader_source);
	DEFINE_LIME_LEGACY_PRIM_2(gl_attach_shader);
	DEFINE_LIME_LEGACY_PRIM_2(gl_detach_shader);
	DEFINE_LIME_LEGACY_PRIM_1(gl_compile_shader);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_shader_parameter);
	DEFINE_LIME_LEGACY_PRIM_1(gl_get_shader_info_log);
	DEFINE_LIME_LEGACY_PRIM_1(gl_get_shader_source);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_shader_precision_format);
	DEFINE_LIME_LEGACY_PRIM_2(gl_bind_buffer);
	DEFINE_LIME_LEGACY_PRIM_5(gl_buffer_data);
	DEFINE_LIME_LEGACY_PRIM_5(gl_buffer_sub_data);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_vertex_attrib_offset);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_vertex_attrib);
	DEFINE_LIME_LEGACY_PRIM_MULT(gl_vertex_attrib_pointer);
	DEFINE_LIME_LEGACY_PRIM_1(gl_enable_vertex_attrib_array);
	DEFINE_LIME_LEGACY_PRIM_1(gl_disable_vertex_attrib_array);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_buffer_paramerter);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_buffer_parameter);
	DEFINE_LIME_LEGACY_PRIM_2(gl_bind_framebuffer);
	DEFINE_LIME_LEGACY_PRIM_2(gl_bind_renderbuffer);
	DEFINE_LIME_LEGACY_PRIM_1(gl_delete_render_buffer);
	DEFINE_LIME_LEGACY_PRIM_4(gl_framebuffer_renderbuffer);
	DEFINE_LIME_LEGACY_PRIM_5(gl_framebuffer_texture2D);
	DEFINE_LIME_LEGACY_PRIM_4(gl_renderbuffer_storage);
	DEFINE_LIME_LEGACY_PRIM_1(gl_check_framebuffer_status);
	DEFINE_LIME_LEGACY_PRIM_3(gl_get_framebuffer_attachment_parameter);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_render_buffer_parameter);
	DEFINE_LIME_LEGACY_PRIM_3(gl_draw_arrays);
	DEFINE_LIME_LEGACY_PRIM_4(gl_draw_elements);
	DEFINE_LIME_LEGACY_PRIM_4(gl_viewport);
	DEFINE_LIME_LEGACY_PRIM_4(gl_scissor);
	DEFINE_LIME_LEGACY_PRIM_1(gl_clear);
	DEFINE_LIME_LEGACY_PRIM_4(gl_clear_color);
	DEFINE_LIME_LEGACY_PRIM_1(gl_clear_depth);
	DEFINE_LIME_LEGACY_PRIM_1(gl_clear_stencil);
	DEFINE_LIME_LEGACY_PRIM_4(gl_color_mask);
	DEFINE_LIME_LEGACY_PRIM_1(gl_depth_func);
	DEFINE_LIME_LEGACY_PRIM_1(gl_depth_mask);
	DEFINE_LIME_LEGACY_PRIM_2(gl_depth_range);
	DEFINE_LIME_LEGACY_PRIM_1(gl_cull_face);
	DEFINE_LIME_LEGACY_PRIM_2(gl_polygon_offset);
	DEFINE_LIME_LEGACY_PRIM_MULT(gl_read_pixels);
	DEFINE_LIME_LEGACY_PRIM_2(gl_pixel_storei);
	DEFINE_LIME_LEGACY_PRIM_2(gl_sample_coverage);
	DEFINE_LIME_LEGACY_PRIM_1(gl_active_texture);
	DEFINE_LIME_LEGACY_PRIM_2(gl_bind_texture);
	DEFINE_LIME_LEGACY_PRIM_1(gl_bind_bitmap_data_texture);
	DEFINE_LIME_LEGACY_PRIM_MULT(gl_tex_image_2d);
	DEFINE_LIME_LEGACY_PRIM_MULT(gl_tex_sub_image_2d);
	DEFINE_LIME_LEGACY_PRIM_MULT(gl_compressed_tex_image_2d);
	DEFINE_LIME_LEGACY_PRIM_MULT(gl_compressed_tex_sub_image_2d);
	DEFINE_LIME_LEGACY_PRIM_3(gl_tex_parameterf);
	DEFINE_LIME_LEGACY_PRIM_3(gl_tex_parameteri);
	DEFINE_LIME_LEGACY_PRIM_MULT(gl_copy_tex_image_2d);
	DEFINE_LIME_LEGACY_PRIM_MULT(gl_copy_tex_sub_image_2d);
	DEFINE_LIME_LEGACY_PRIM_1(gl_generate_mipmap);
	DEFINE_LIME_LEGACY_PRIM_2(gl_get_tex_parameter);
	DEFINE_LIME_LEGACY_PRIM_1(gl_is_buffer);
	DEFINE_LIME_LEGACY_PRIM_1(gl_is_program);
	DEFINE_LIME_LEGACY_PRIM_1(gl_is_renderbuffer);
	DEFINE_LIME_LEGACY_PRIM_1(gl_is_framebuffer);
	DEFINE_LIME_LEGACY_PRIM_1(gl_is_shader);
	DEFINE_LIME_LEGACY_PRIM_1(gl_is_texture);
	DEFINE_LIME_LEGACY_PRIM_1(gl_delete_texture);
	DEFINE_LIME_LEGACY_PRIM_1(gl_delete_shader);
	DEFINE_LIME_LEGACY_PRIM_1(gl_delete_program);
	DEFINE_LIME_LEGACY_PRIM_1(gl_delete_framebuffer);
	DEFINE_LIME_LEGACY_PRIM_1(gl_delete_renderbuffer);
	DEFINE_LIME_LEGACY_PRIM_1(gl_delete_buffer);
	DEFINE_LIME_LEGACY_PRIM_0(gl_create_texture);
	DEFINE_LIME_LEGACY_PRIM_0(gl_create_buffer);
	DEFINE_LIME_LEGACY_PRIM_0(gl_create_framebuffer);
	DEFINE_LIME_LEGACY_PRIM_0(gl_create_render_buffer);
	DEFINE_LIME_LEGACY_PRIM_2(gl_uniform1i);
	DEFINE_LIME_LEGACY_PRIM_2(gl_uniform1f);
	DEFINE_LIME_LEGACY_PRIM_3(gl_uniform2i);
	DEFINE_LIME_LEGACY_PRIM_3(gl_uniform2f);
	DEFINE_LIME_LEGACY_PRIM_4(gl_uniform3i);
	DEFINE_LIME_LEGACY_PRIM_4(gl_uniform3f);
	DEFINE_LIME_LEGACY_PRIM_5(gl_uniform4i);
	DEFINE_LIME_LEGACY_PRIM_5(gl_uniform4f);
	
	
	namespace S3D {
		
		
		#ifdef NME_S3D
		DEFINE_LIME_LEGACY_PRIM_0(get_s3d_enabled);
		DEFINE_LIME_LEGACY_PRIM_1(set_s3d_enabled);
		DEFINE_LIME_LEGACY_PRIM_0(get_s3d_supported);
		#else
		value nme_get_s3d_enabled() { return alloc_bool(false); }
		value nme_set_s3d_enabled(value inVal) { return inVal; }
		value nme_get_s3d_supported() { return alloc_bool(false); }
		DEFINE_LIME_LEGACY_PRIM_0(get_s3d_enabled);
		DEFINE_LIME_LEGACY_PRIM_1(set_s3d_enabled);
		DEFINE_LIME_LEGACY_PRIM_0(get_s3d_supported);
		#endif
	
		
	}
	
	
	#ifdef NME_S3D
	DEFINE_LIME_LEGACY_PRIM_0(gl_s3d_get_eye_separation);
	DEFINE_LIME_LEGACY_PRIM_1(gl_s3d_set_eye_separation);
	DEFINE_LIME_LEGACY_PRIM_0(gl_s3d_get_focal_length);
	DEFINE_LIME_LEGACY_PRIM_1(gl_s3d_set_focal_length);
	#endif
	
	
	value lime_window_alert (value message, value title) {
		
		#ifdef NME_SDL2
		
		SDL_Window* sdlWindow = SDL_GL_GetCurrentWindow ();
		if (!sdlWindow) return alloc_null ();
		
		#ifdef HX_WINDOWS
		
		int count = 0;
		int speed = 0;
		bool stopOnForeground = true;
		
		SDL_SysWMinfo info;
		SDL_VERSION (&info.version);
		SDL_GetWindowWMInfo (sdlWindow, &info);
		
		FLASHWINFO fi;
		fi.cbSize = sizeof (FLASHWINFO);
		fi.hwnd = info.info.win.window;
		fi.dwFlags = stopOnForeground ? FLASHW_ALL | FLASHW_TIMERNOFG : FLASHW_ALL | FLASHW_TIMER;
		fi.uCount = count;
		fi.dwTimeout = speed;
		FlashWindowEx (&fi);
		
		#endif
		
		if (!val_is_null (message)) {
			
			SDL_ShowSimpleMessageBox (SDL_MESSAGEBOX_INFORMATION, val_is_null (title) ? "" : val_string (title), val_string (message), sdlWindow);
			
		}
		
		#endif
		
		return alloc_null ();
		
	}
	
	
	DEFINE_PRIM (lime_window_alert, 2);
	
	
}


extern "C" int nme_register_prims();

extern "C" int lime_legacy_register_prims()
{
	nme_register_prims();
	return 0;
}