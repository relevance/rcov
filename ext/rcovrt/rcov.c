
#include <ruby.h>
#include <env.h>
#include <node.h>
#include <st.h>
#include <stdlib.h>

#define RCOVRT_VERSION_MAJOR 2
#define RCOVRT_VERSION_MINOR 0
#define RCOVRT_VERSION_REV   0

static VALUE mRcov;
static VALUE mRCOV__;
static VALUE oSCRIPT_LINES__;
static ID id_cover;
static st_table* coverinfo = 0;
static char coverage_hook_set_p;
static char callsite_hook_set_p;

struct cov_array {
        unsigned int len;
        unsigned int *ptr;
};

static struct cov_array *cached_array = 0;
static char *cached_file = 0; 

typedef struct {
        char *sourcefile;
        unsigned int sourceline;
        VALUE curr_meth;
} type_def_site;       
static VALUE caller_info = 0;
static VALUE method_def_site_info = 0;

static caller_stack_len = 1;

/*
 *
 * callsite hook and associated functions
 *
 * */

static VALUE
record_callsite_info(VALUE args)
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
          /* Qnil, anything else should be impossible unless somebody's been
           * messing with ObjectSpace */
          count_hash = rb_hash_new();
          rb_hash_aset(caller_info, curr_meth, count_hash);
  }
  count = rb_hash_aref(count_hash, caller_ary);
  if(count == Qnil) 
          count = INT2FIX(0);
  count = INT2FIX(FIX2UINT(count) + 1);
  rb_hash_aset(count_hash, caller_ary, count);
  /*
  printf("CALLSITE: %s -> %s   %d\n", RSTRING(rb_inspect(curr_meth))->ptr,
                  RSTRING(rb_inspect(caller_ary))->ptr, FIX2INT(count));
  */

  return Qnil;
}


static VALUE
record_method_def_site(VALUE args)
{
  type_def_site *pargs = (type_def_site *)args;
  VALUE def_site_info;
  VALUE hash;

  if( RTEST(rb_hash_aref(method_def_site_info, pargs->curr_meth)) )
          return Qnil;
  def_site_info = rb_ary_new();
  rb_ary_push(def_site_info, rb_str_new2(pargs->sourcefile));
  rb_ary_push(def_site_info, INT2NUM(pargs->sourceline+1));
  rb_hash_aset(method_def_site_info, pargs->curr_meth, def_site_info);
  /*
  printf("DEFSITE: %s:%d  for %s\n", pargs->sourcefile, pargs->sourceline+1,
                  RSTRING(rb_inspect(pargs->curr_meth))->ptr);
  */
  
  return Qnil;
}

static VALUE
callsite_custom_backtrace(int lev)
{
  struct FRAME *frame = ruby_frame;
  VALUE ary;
  NODE *n;
  VALUE level;
  VALUE klass;

  ary = rb_ary_new();
  if (frame->last_func == ID_ALLOCATOR) {
          frame = frame->prev;
  }
  for (; frame && (n = frame->node); frame = frame->prev) {
          if (frame->prev && frame->prev->last_func) {
                  if (frame->prev->node == n) continue;
                  level = rb_ary_new();
                  klass = frame->prev->last_class ? frame->prev->last_class : Qnil;
                  if(TYPE(klass) == T_ICLASS) {
                          klass = CLASS_OF(klass);
                  }
                  rb_ary_push(level, klass);
                  rb_ary_push(level, ID2SYM(frame->prev->last_func));
                  rb_ary_push(level, rb_str_new2(n->nd_file));
                  rb_ary_push(level, INT2NUM(nd_line(n)));
          }
          else {
                  level = rb_ary_new();
                  rb_ary_push(level, Qnil);
                  rb_ary_push(level, Qnil);
                  rb_ary_push(level, rb_str_new2(n->nd_file));
                  rb_ary_push(level, INT2NUM(nd_line(n)));
          }
          rb_ary_push(ary, level);
          if(--lev == 0)
                  break;
  }

  return ary;
}
  
static void
coverage_event_callsite_hook(rb_event_t event, NODE *node, VALUE self, 
                ID mid, VALUE klass)
{
 VALUE caller_ary;
 VALUE curr_meth;
 VALUE args[2];
 int status;

 caller_ary = callsite_custom_backtrace(caller_stack_len);

 if(TYPE(klass) == T_ICLASS) {
         klass = CLASS_OF(klass);
 }
 curr_meth = rb_ary_new();
 rb_ary_push(curr_meth, klass);
 rb_ary_push(curr_meth, ID2SYM(mid));

 args[0] = caller_ary;
 args[1] = curr_meth;
 rb_protect(record_callsite_info, (VALUE)args, &status);
 if(!status && node) {
         type_def_site args;        
         
         args.sourcefile = node->nd_file;
         args.sourceline = nd_line(node) - 1;
         args.curr_meth = curr_meth;
         rb_protect(record_method_def_site, (VALUE)&args, 0);
 }
 if(status)
         rb_gv_set("$!", Qnil);
}


static VALUE
cov_install_callsite_hook(VALUE self)
{
  if(!callsite_hook_set_p) {
          if(TYPE(caller_info) != T_HASH)
                  caller_info = rb_hash_new();
          callsite_hook_set_p = 1;
          rb_add_event_hook(coverage_event_callsite_hook, 
                          RUBY_EVENT_CALL);
          
          return Qtrue;
  } else
          return Qfalse;
}


static VALUE
cov_remove_callsite_hook(VALUE self)
{
 if(!callsite_hook_set_p) 
         return Qfalse;
 else {
         rb_remove_event_hook(coverage_event_callsite_hook);
         callsite_hook_set_p = 0;
         return Qtrue;
 }
}


static VALUE
cov_generate_callsite_info(VALUE self)
{
  VALUE ret;

  ret = rb_ary_new();
  rb_ary_push(ret, caller_info);
  rb_ary_push(ret, method_def_site_info);
  return ret;
}


static VALUE
cov_reset_callsite(VALUE self)
{
  if(callsite_hook_set_p) {
	  rb_raise(rb_eRuntimeError, 
		  "Cannot reset the callsite info in the middle of a traced run.");
	  return Qnil;
  }

  caller_info = rb_hash_new();
  method_def_site_info = rb_hash_new();
  return Qnil;
}

/* 
 *
 * coverage hook and associated functions 
 *
 * */

static struct cov_array *
coverage_increase_counter_uncached(char *sourcefile, int sourceline,
                                   char mark_only)
{
  struct cov_array *carray;
  
  if(!st_lookup(coverinfo, (st_data_t)sourcefile, (st_data_t*)&carray)) {
          VALUE arr;

          arr = rb_hash_aref(oSCRIPT_LINES__, rb_str_new2(sourcefile));
          if(NIL_P(arr)) 
                  return 0;
          rb_check_type(arr, T_ARRAY);
          carray = calloc(1, sizeof(struct cov_array));
          carray->ptr = calloc(RARRAY(arr)->len, sizeof(unsigned int));
          carray->len = RARRAY(arr)->len;
          st_insert(coverinfo, (st_data_t)strdup(sourcefile), 
                          (st_data_t) carray);
  }
  if(mark_only) {
          if(!carray->ptr[sourceline])
                  carray->ptr[sourceline] = 1;
  } else {
          carray->ptr[sourceline]++;
  }

  return carray;
}


static void
coverage_mark_caller()
{
  struct FRAME *frame = ruby_frame;
  NODE *n;

  if (frame->last_func == ID_ALLOCATOR) {
          frame = frame->prev;
  }
  for (; frame && (n = frame->node); frame = frame->prev) {
          if (frame->prev && frame->prev->last_func) {
                  if (frame->prev->node == n) continue;
                  coverage_increase_counter_uncached(n->nd_file, nd_line(n), 1);
          }
          else {
                  coverage_increase_counter_uncached(n->nd_file, nd_line(n), 1);
          }
          break;
  }
}


static void
coverage_increase_counter_cached(char *sourcefile, int sourceline)
{
 if(cached_file == sourcefile && cached_array) {
         cached_array->ptr[sourceline]++;
         return;
 }
 cached_file = sourcefile;
 cached_array = coverage_increase_counter_uncached(sourcefile, sourceline, 0);
}


static void
coverage_event_coverage_hook(rb_event_t event, NODE *node, VALUE self, 
                ID mid, VALUE klass)
{
 char *sourcefile;
 unsigned int sourceline;
 
 if(event & (RUBY_EVENT_C_CALL | RUBY_EVENT_C_RETURN | RUBY_EVENT_CLASS))
         return;
 
 if(!node)
         return;

 sourcefile = node->nd_file;
 sourceline = nd_line(node) - 1;

 coverage_increase_counter_cached(sourcefile, sourceline);
 if(event == RUBY_EVENT_CALL)
         coverage_mark_caller();
}


static VALUE
cov_install_coverage_hook(VALUE self)
{
  if(!coverage_hook_set_p) {
	  if(!coverinfo)
		  coverinfo = st_init_strtable();
          coverage_hook_set_p = 1;
          rb_add_event_hook(coverage_event_coverage_hook, 
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
cov_remove_coverage_hook(VALUE self)
{
 if(!coverage_hook_set_p) 
         return Qfalse;
 else {
         rb_remove_event_hook(coverage_event_coverage_hook);
         coverage_hook_set_p = 0;
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
cov_reset_coverage(VALUE self)
{
  if(coverage_hook_set_p) {
	  rb_raise(rb_eRuntimeError, 
		  "Cannot reset the coverage info in the middle of a traced run.");
	  return Qnil;
  }

  cached_array = 0;
  cached_file = 0;
  st_foreach(coverinfo, free_table, Qnil); 
  st_free_table(coverinfo);
  coverinfo = 0;

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
 method_def_site_info = rb_hash_new();
 rb_gc_register_address(&caller_info);
 rb_gc_register_address(&method_def_site_info);

 coverage_hook_set_p = 0;

 rb_define_singleton_method(mRCOV__, "install_coverage_hook", 
                 cov_install_coverage_hook, 0);
 rb_define_singleton_method(mRCOV__, "remove_coverage_hook", 
                 cov_remove_coverage_hook, 0);
 rb_define_singleton_method(mRCOV__, "install_callsite_hook", 
                 cov_install_callsite_hook, 0);
 rb_define_singleton_method(mRCOV__, "remove_callsite_hook", 
                 cov_remove_callsite_hook, 0);
 rb_define_singleton_method(mRCOV__, "generate_coverage_info", 
		 cov_generate_coverage_info, 0);
 rb_define_singleton_method(mRCOV__, "generate_callsite_info", 
		 cov_generate_callsite_info, 0);
 rb_define_singleton_method(mRCOV__, "reset_coverage", cov_reset_coverage, 0);
 rb_define_singleton_method(mRCOV__, "reset_callsite", cov_reset_callsite, 0);
 rb_define_singleton_method(mRCOV__, "ABI", cov_ABI, 0);
}
/* vim: set sw=8 expandtab: */
