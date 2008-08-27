import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.runtime.Frame;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.RubyEvent;
import org.jruby.runtime.builtin.IRubyObject;

public class CallsiteHook extends RcovHook {

    private static CallsiteHook callsiteHook;

    public static CallsiteHook getCallsiteHook() {
        if (callsiteHook == null) {
            callsiteHook = new CallsiteHook();
        }        
        return callsiteHook;
    }

    private boolean active;
    private RubyHash defsites;
    private RubyHash callsites;
    private Pattern backtracePattern;

    private CallsiteHook() {
        super();
        backtracePattern = Pattern.compile("^([^:]*):(\\d+)(:in `(.*)')?$");
    }

    public boolean isActive() {
        return active;
    }

    public boolean isInterestedInEvent(RubyEvent event) {
        return event == RubyEvent.CALL || event == RubyEvent.C_CALL;
    }

    public RubyArray getCallsiteInfo(Ruby runtime) {
        RubyArray info = runtime.newArray();
        info.add(getCallsites(runtime));
        info.add(getDefsites(runtime));
        return info;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public RubyHash resetDefsites() {
        defsites.clear();
        return defsites;
    }

    public void eventHandler(ThreadContext context, String event, String file, int line,
            String name, IRubyObject type) {
        RubyArray currentMethod = context.getRuntime().newArray();
        currentMethod.add(context.getFrameKlazz());
        currentMethod.add(context.getRuntime().newSymbol(name));

        RubyArray fileLoc = context.getRuntime().newArray();
        fileLoc.add(file);
        fileLoc.add(Long.valueOf(line));
        
        defsites = getDefsites(context.getRuntime());
        defsites.put(currentMethod, fileLoc);

        callsites = getCallsites(context.getRuntime());
        if (!callsites.containsKey(currentMethod)) {
            callsites.put(currentMethod, RubyHash.newHash(context.getRuntime()));
        }
        RubyHash hash = (RubyHash) callsites.get(currentMethod);

        RubyArray callerArray = customBacktrace(context);
        if (!hash.containsKey(callerArray)) {
            hash.put(callerArray, Long.valueOf(0));
        }
        Long count = (Long) hash.get(callerArray);
        long itCount = count.longValue() + 1L;
        hash.put(callerArray, Long.valueOf(itCount));

    }

    private RubyArray customBacktrace(ThreadContext context) {
        StackTraceElement[] frames = context.createBacktrace2(1, false);
        RubyArray backtrace = (RubyArray) ThreadContext
                .createBacktraceFromFrames(context.getRuntime(), frames);

        RubyArray ary = context.getRuntime().newArray();        
        ary.add(frames[frames.length - 1]);
        ary.addAll(formatBacktrace(context.getRuntime(), (String) backtrace.get(1)));

        return context.getRuntime().newArray((IRubyObject) ary);
    }

    /**
     * TODO: The logic in this method really needs to be wrapped in a backtrace
     * object or something. Then I could fix the file path issues that cause
     * test failures.
     * @param runtime
     * @param backtrace
     * @return
     */
    private RubyArray formatBacktrace(Ruby runtime, String backtrace) {
        RubyArray ary = runtime.newArray();
        if ( backtrace == null ) {
            ary.add(runtime.getNil());
            ary.add("");
            ary.add(Long.valueOf(0));
        } else {
            Matcher matcher = backtracePattern.matcher(backtrace);

            if (matcher.matches()) {            
                String method = matcher.group(4);
                String file = matcher.group(1);
                String line = matcher.group(2);
                Long lineNum = ( line == null ? 
                                 Long.valueOf( 0 ) : 
                                 Long.valueOf( line ) );

                ary.add( ( method == null ? 
                           runtime.getNil() : 
                           runtime.newSymbol( method ) ) );
                ary.add(file);
                ary.add(lineNum);
            }
        }

        return ary;
    }

    private RubyHash getCallsites(Ruby runtime) {
        if (this.callsites == null) {
            this.callsites = RubyHash.newHash(runtime);
        }
        return this.callsites;
    }

    private RubyHash getDefsites(Ruby runtime) {
        if (this.defsites == null) {
            this.defsites = RubyHash.newHash(runtime);
        }
        return this.defsites;
    }

}
