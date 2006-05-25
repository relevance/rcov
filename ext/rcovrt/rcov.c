
#include <ruby.h>
#include <node.h>
#include <st.h>
#include <stdlib.h>

#define RCOVRT_VERSION_MAJOR 0
#define RCOVRT_VERSION_MINOR 2
#define RCOVRT_VERSION_REV   0

static VALUE mRcov;
static VALUE mRCOV__;
static VALUE oSCRIPT_LINES__;
static ID id_cover;
static VALUE id_caller = 0;
static st_table* coverinfo = 0;
static char hook_set_p;

struct cov_array {
        unsigned int len;
        unsigned int *ptr;
};

static struct cov_array *cached_array = 0;
static char *cached_file = 0; 

static VALUE caller_info = 0;

static caller_stack_len = 1;

static VALUE
record_call_trace_info(VALUE args)
{
  VALUE caller_ary;
  VALUE curr_meth;
  VALUE count_hash;
  VALUE count;
  VALUE *pargs = (VALUE *)args;

  caller_ary = pargs[0];
  curr_meth = pargs[1];
  count_hash = rb_hash_aref(caller_info, curr_meth);
  if(TYPE(count_hash) != T_HASH) { 
          /* Qnil, anything else should be impossible */
          count_hash = rb_hash_new();
          rb_hash_aset(caller_info, curr_meth, count_hash);
  }
  count = rb_hash_aref(count_hash, caller_ary);
  if(count == Qnil) 
          count = INT2FIX(0);
  count = INT2FIX(FIX2UINT(count) + 1);
  rb_hash_aset(count_hash, caller_ary, count);

  return Qnil;
}

static void
coverage_event_hook(rb_event_t event, NODE *node, VALUE self, 
                ID mid, VALUE klass)
{
 char *sourcefile;
 unsigned int sourceline;
 
 if(event == RUBY_EVENT_CALL) {
         VALUE caller_ary;
         VALUE aref_args[2];
         VALUE curr_meth;
         VALUE args[2];

         caller_ary = rb_funcall(rb_mKernel, id_caller, 0);
         aref_args[0] = INT2FIX(0);
         aref_args[1] = INT2NUM(caller_stack_len);
         caller_ary = rb_ary_aref(2, aref_args, caller_ary);

         curr_meth = rb_ary_new();
         rb_ary_push(curr_meth, klass);
         rb_ary_push(curr_meth, ID2SYM(mid));

         args[0] = caller_ary;
         args[1] = curr_meth;
         rb_protect(record_call_trace_info, (VALUE)args, 0);
 }

 if(event & (RUBY_EVENT_C_CALL | RUBY_EVENT_C_RETURN | RUBY_EVENT_CLASS))
         return;
 
 if(!node)
         return;

 sourcefile = node->nd_file;
 sourceline = nd_line(node) - 1;


 if(cached_file == sourcefile && cached_array) {
         cached_array->ptr[sourceline]++;
         return;
 }
 

 if(!st_lookup(coverinfo, (st_data_t)sourcefile, (st_data_t*)&cached_array)) {
         VALUE arr;

         arr = rb_hash_aref(oSCRIPT_LINES__, rb_str_new2(sourcefile));
         if(NIL_P(arr)) 
                 return;
         rb_check_type(arr, T_ARRAY);
         cached_array = calloc(1, sizeof(struct cov_array));
         cached_array->ptr = calloc(RARRAY(arr)->len, sizeof(unsigned int));
         cached_array->len = RARRAY(arr)->len;
         st_insert(coverinfo, (st_data_t)strdup(sourcefile), 
                   (st_data_t) cached_array);
 }
 cached_file = sourcefile;
 cached_array->ptr[sourceline]++;
}


static VALUE
cov_install_hook(VALUE self)
{
  if(!hook_set_p) {
	  if(!coverinfo)
		  coverinfo = st_init_strtable();
          hook_set_p = 1;
          rb_add_event_hook(coverage_event_hook, 
                       RUBY_EVENT_ALL & ~RUBY_EVENT_C_CALL &
                       ~RUBY_EVENT_C_RETURN & ~RUBY_EVENT_CLASS);
          
          return Qtrue;
  }
  else
          return Qfalse;
}


static int
populate_cover(st_data_t key, st_data_t value, st_data_t cover)
{
 VALUE rcover;
 VALUE rkey;
 VALUE rval;
 struct cov_array *carray;
 unsigned int i;
 
 rcover = (VALUE)cover;
 carray = (struct cov_array *) value;
 rkey = rb_str_new2((char*) key);
 rval = rb_ary_new2(carray->len);
 for(i = 0; i < carray->len; i++)
         RARRAY(rval)->ptr[i] = UINT2NUM(carray->ptr[i]);
 RARRAY(rval)->len = carray->len;

 rb_hash_aset(rcover, rkey, rval);
 
 return ST_CONTINUE;
}


static int
free_table(st_data_t key, st_data_t value, st_data_t ignored)
{
 struct cov_array *carray;
 
 carray = (struct cov_array *) value;
 free((char *)key);
 free(carray->ptr);
 free(carray);

 return ST_CONTINUE;
}


static VALUE
cov_remove_hook(VALUE self)
{
 if(!hook_set_p) 
         return Qfalse;
 else {
         rb_remove_event_hook(coverage_event_hook);
         hook_set_p = 0;
         return Qtrue;
 }
}


static VALUE
cov_generate_coverage_info(VALUE self)
{
  VALUE cover;

  if(rb_const_defined_at(mRCOV__, id_cover)) {
	  rb_mod_remove_const(mRCOV__, ID2SYM(id_cover));
  }

  cover = rb_hash_new();
  if(coverinfo)
	  st_foreach(coverinfo, populate_cover, cover);
  rb_define_const(mRCOV__, "COVER", cover);

  return cover;
}

static VALUE
cov_generate_callsite_info(VALUE self)
{
  return caller_info;
}

static VALUE
cov_reset(VALUE self)
{
  if(hook_set_p) {
	  rb_raise(rb_eRuntimeError, 
		  "Cannot reset the coverate info in the middle of a traced run.");
	  return Qnil;
  }

  cached_array = 0;
  cached_file = 0;
  st_foreach(coverinfo, free_table, Qnil); 
  st_free_table(coverinfo);
  coverinfo = 0;

  caller_info = rb_hash_new();
  return Qnil;
}

static VALUE
cov_ABI(VALUE self)
{
  VALUE ret;

  ret = rb_ary_new();
  rb_ary_push(ret, INT2FIX(RCOVRT_VERSION_MAJOR));
  rb_ary_push(ret, INT2FIX(RCOVRT_VERSION_MINOR));
  rb_ary_push(ret, INT2FIX(RCOVRT_VERSION_REV));

  return ret;
}

void
Init_rcovrt()
{
 ID id_rcov = rb_intern("Rcov");
 ID id_coverage__ = rb_intern("RCOV__");
 ID id_script_lines__ = rb_intern("SCRIPT_LINES__");
 
 id_cover = rb_intern("COVER");
 id_caller = rb_intern("caller");

 if(rb_const_defined(rb_cObject, id_rcov)) 
         mRcov = rb_const_get(rb_cObject, id_rcov);
 else
         mRcov = rb_define_module("Rcov");

 if(rb_const_defined(mRcov, id_coverage__))
         mRCOV__ = rb_const_get_at(mRcov, id_coverage__);
 else
         mRCOV__ = rb_define_module_under(mRcov, "RCOV__");

 if(rb_const_defined(rb_cObject, id_script_lines__))
         oSCRIPT_LINES__ = rb_const_get(rb_cObject, rb_intern("SCRIPT_LINES__"));
 else {
         oSCRIPT_LINES__ = rb_hash_new();
         rb_const_set(rb_cObject, id_script_lines__, oSCRIPT_LINES__);
 }

 caller_info = rb_hash_new();
 rb_gc_register_address(&caller_info);

 hook_set_p = 0;

 rb_define_singleton_method(mRCOV__, "install_hook", cov_install_hook, 0);
 rb_define_singleton_method(mRCOV__, "remove_hook", cov_remove_hook, 0);
 rb_define_singleton_method(mRCOV__, "generate_coverage_info", 
		 cov_generate_coverage_info, 0);
 rb_define_singleton_method(mRCOV__, "generate_callsite_info", 
		 cov_generate_callsite_info, 0);
 rb_define_singleton_method(mRCOV__, "reset", cov_reset, 0);
 rb_define_singleton_method(mRCOV__, "ABI", cov_ABI, 0);
}
/* vim: set sw=8 expandtab: */
