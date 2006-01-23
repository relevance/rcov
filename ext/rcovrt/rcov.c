
#include <ruby.h>
#include <node.h>
#include <st.h>
#include <stdlib.h>

static VALUE mRcov;
static VALUE mCOVERAGE__;
static VALUE oSCRIPT_LINES__;
static ID id_cover;
static st_table* coverinfo;
static char hook_set_p;

struct cov_array {
        unsigned int len;
        unsigned int *ptr;
};


static void
coverage_event_hook(rb_event_t event, NODE *node, VALUE self, 
                ID mid, VALUE klass)
{
 static struct cov_array *cached_array = 0;
 static char *cached_file = 0; 
 
 char *sourcefile;
 unsigned int sourceline;
 
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
 VALUE cover;
 
 if(!hook_set_p) 
         return Qfalse;
 else {
         rb_remove_event_hook(coverage_event_hook);
	 if(rb_const_defined_at(mCOVERAGE__, id_cover)) {
		 rb_mod_remove_const(mCOVERAGE__, ID2SYM(id_cover));
	 }
         
         cover = rb_hash_new();
         st_foreach(coverinfo, populate_cover, cover);
         rb_define_const(mCOVERAGE__, "COVER", cover);
         st_foreach(coverinfo, free_table, cover);
         st_free_table(coverinfo);
         coverinfo = 0;
         hook_set_p = 0;
         return Qtrue;
 }
}

void
Init_rcovrt()
{
 ID id_rcov = rb_intern("Rcov");
 ID id_coverage__ = rb_intern("COVERAGE__");
 ID id_script_lines__ = rb_intern("SCRIPT_LINES__");
 
 id_cover = rb_intern("COVER");

 if(rb_const_defined(rb_cObject, id_rcov)) 
         mRcov = rb_const_get(rb_cObject, id_rcov);
 else
         mRcov = rb_define_module("Rcov");

 if(rb_const_defined(mRcov, id_coverage__))
         mCOVERAGE__ = rb_const_get_at(mRcov, id_coverage__);
 else
         mCOVERAGE__ = rb_define_module_under(mRcov, "COVERAGE__");

 if(rb_const_defined(rb_cObject, id_script_lines__))
         oSCRIPT_LINES__ = rb_const_get(rb_cObject, rb_intern("SCRIPT_LINES__"));
 else {
         oSCRIPT_LINES__ = rb_hash_new();
         rb_const_set(rb_cObject, id_script_lines__, oSCRIPT_LINES__);
 }

 hook_set_p = 0;

 rb_define_singleton_method(mCOVERAGE__, "install_hook", cov_install_hook, 0);
 rb_define_singleton_method(mCOVERAGE__, "remove_hook", cov_remove_hook, 0);
}
