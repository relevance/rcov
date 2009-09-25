import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.RubyEvent;
import org.jruby.runtime.builtin.IRubyObject;

public class CoverageHook extends RcovHook {
  
  private static CoverageHook hook;
  
  public static CoverageHook getCoverageHook() {
    if (hook == null) {
      hook = new CoverageHook();
    }
    
    return hook;
  }
  
  private boolean active;
  private RubyHash cover;
  
  private CoverageHook() {
    super();
  }
  
  public boolean isActive() {
    return active;
  }
  
  public void setActive(boolean active) {
    this.active = active;
  }
  
  public void eventHandler(ThreadContext context, String event, String file, int line, String name, IRubyObject type) {
    //Line numbers are 1s based.  Arrays are zero based.  We need to compensate for that.
    line -= 1;
    
    // Make sure that we have SCRIPT_LINES__ and it's a hash
    RubyHash scriptLines = getScriptLines(context.getRuntime());
    if (scriptLines == null || !scriptLines.containsKey(file)) {
      return;
    }
    
    // make sure the file's source lines are in SCRIPT_LINES__
    cover = getCover(context.getRuntime());
    RubyArray lines = (RubyArray) scriptLines.get(file);
    if (lines == null || cover == null){
      return;
    }
    
    // make sure file's counts are in COVER and set to zero
    RubyArray counts = (RubyArray) cover.get(file);
    if (counts == null) {
      counts = context.getRuntime().newArray();
      for (int i = 0; i < lines.size(); i++) {
        counts.add(Long.valueOf(0));
      }
      cover.put(file, counts);
    }
    
    // in the case of code generation (one example is instance_eval for routes optimization)
    // We could get here and see that we are not matched up with what we expect
    if (counts.size() <= line ) {
      for (int i=counts.size(); i<= line; i++) {
        counts.add(Long.valueOf(0));
      }
    }
    
    if (!context.isWithinTrace()) {
      try {
        context.setWithinTrace(true);
        // update counts in COVER
        Long count = (Long) counts.get(line);
        if (count == null) {
          count = Long.valueOf(0);
        }
        count = Long.valueOf(count.longValue() + 1);
        counts.set(line , count);
      }
      finally{
        context.setWithinTrace(false);
      }
    }
  }
  
  public boolean isInterestedInEvent(RubyEvent event) {
    return event == RubyEvent.CALL || event == RubyEvent.LINE || event == RubyEvent.RETURN || event == RubyEvent.CLASS || event == RubyEvent.C_RETURN || event == RubyEvent.C_CALL;
  }
  
  /*
   * Returns the COVER hash, setting up the COVER constant if necessary.
   * @param runtime
   * @return
   */
  public RubyHash getCover(Ruby runtime) {
    if (cover == null) {
      cover = RubyHash.newHash(runtime);
    }
    
    return cover;
  }
  
  public RubyHash getScriptLines(Ruby runtime) {
    IRubyObject scriptLines = runtime.getObject().getConstantAt("SCRIPT_LINES__");
    if (scriptLines instanceof RubyHash) {
      return (RubyHash) scriptLines;
    } else {
      return null;
    }
  }
  
  public IRubyObject resetCoverage(Ruby runtime) {
    getCover(runtime).clear();
    return runtime.getNil();
  }
}
