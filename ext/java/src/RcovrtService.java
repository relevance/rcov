import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyModule;
import org.jruby.RubyObjectAdapter;
import org.jruby.RubySymbol;
import org.jruby.exceptions.RaiseException;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.load.BasicLibraryService;
import org.jruby.javasupport.JavaEmbedUtils;
import org.jruby.javasupport.JavaUtil;

public class RcovrtService implements BasicLibraryService {
    
    private static RubyObjectAdapter rubyApi;

    public boolean basicLoad(Ruby runtime) {
        RubyModule rcov = runtime.getOrCreateModule("Rcov");
        RubyModule rcov__ = runtime.defineModuleUnder("RCOV__", rcov);

        IRubyObject sl = runtime.getObject().getConstantAt("SCRIPT_LINES__");
        if (sl == null) {
            runtime.getObject().setConstant("SCRIPT_LINES__", RubyHash.newHash(runtime));
        }
        
        rubyApi = JavaEmbedUtils.newObjectAdapter();
        rcov__.defineAnnotatedMethods(RcovrtService.class);
        return true;
    }


    @JRubyMethod(name="reset_callsite", meta = true)
    public static IRubyObject resetCallsite(IRubyObject recv) {
        CallsiteHook hook = CallsiteHook.getCallsiteHook();
        if (hook.isActive()) {
            throw RaiseException.createNativeRaiseException(
                    recv.getRuntime(),
                    new RuntimeException("Cannot reset the callsite info in the middle of a traced run."),null);
        }
        return hook.resetDefsites();
    }

    @JRubyMethod(name="reset_coverage", meta = true)
    public static IRubyObject resetCoverage(IRubyObject recv) {
        CoverageHook hook = CoverageHook.getCoverageHook();
        if (hook.isActive()) {
            throw RaiseException.createNativeRaiseException(
                    recv.getRuntime(),
                    new RuntimeException("Cannot reset the coverage info in the middle of a traced run."), null);
        }
        return hook.resetCoverage(recv.getRuntime());
    }

    @JRubyMethod(name="remove_coverage_hook", meta = true)
    public static IRubyObject removeCoverageHook(IRubyObject recv) {
        return removeRcovHook(recv, CoverageHook.getCoverageHook());
    }

    @JRubyMethod(name="install_coverage_hook", meta = true)
    public static IRubyObject installCoverageHook(IRubyObject recv) {
        return installRcovHook(recv, CoverageHook.getCoverageHook());
    }

    /**
       TODO: I think this is broken. I'm not sure why, but recreating
       cover all the time seems bad.
    */
    @JRubyMethod(name="generate_coverage_info", meta = true)
    public static IRubyObject generateCoverageInfo(IRubyObject recv) {
        Ruby run = recv.getRuntime();
        RubyHash cover = (RubyHash)CoverageHook.getCoverageHook().getCover(run);
        RubyHash xcover = RubyHash.newHash(run);
        RubyArray keys = cover.keys();
        RubyArray temp;
        ThreadContext  ctx = run.getCurrentContext();
        for (int i=0; i < keys.length().getLongValue(); i++) {
            IRubyObject key = keys.aref(JavaUtil.convertJavaToRuby(run, Long.valueOf(i)));
            temp = ((RubyArray)cover.op_aref(ctx, key)).aryDup();
            xcover.op_aset(ctx,key, temp);
        }
        RubyModule rcov__ = (RubyModule) recv.getRuntime().getModule("Rcov").getConstant("RCOV__");

        if (rcov__.const_defined_p(ctx, RubySymbol.newSymbol(recv.getRuntime(), "COVER")).isTrue()) {
            rcov__.remove_const(ctx, recv.getRuntime().newString("COVER"));
        } 
        rcov__.defineConstant( "COVER", xcover );

        return xcover;
   }

    @JRubyMethod(name="remove_callsite_hook", meta = true)
    public static IRubyObject removeCallsiteHook(IRubyObject recv) {
        return removeRcovHook( recv, CallsiteHook.getCallsiteHook() );
    }

    @JRubyMethod(name="install_callsite_hook", meta = true)
    public static IRubyObject installCallsiteHook(IRubyObject recv) {
        return installRcovHook( recv, CallsiteHook.getCallsiteHook() );
    }

    @JRubyMethod(name="generate_callsite_info", meta = true)
    public static IRubyObject generateCallsiteInfo(IRubyObject recv) {
        return CallsiteHook.getCallsiteHook().getCallsiteInfo( recv.getRuntime() ).dup();
    }

    @JRubyMethod(name="ABI", meta = true)
    public static IRubyObject getAbi( IRubyObject recv ) {
        RubyArray ary = recv.getRuntime().newArray();
        ary.add( RubyFixnum.int2fix( recv.getRuntime(), 2L ) );
        ary.add( RubyFixnum.int2fix( recv.getRuntime(), 0L ) );
        ary.add( RubyFixnum.int2fix( recv.getRuntime(), 0L ) );
        return ary;
    }
    
    private static IRubyObject removeRcovHook( IRubyObject recv, RcovHook hook ) {
        hook.setActive( false );
        recv.getRuntime().removeEventHook( hook );
        return recv.getRuntime().getFalse();
    }
    
    private static IRubyObject installRcovHook( IRubyObject recv, RcovHook hook ) {
        if ( !hook.isActive() ) {
            hook.setActive( true );
            recv.getRuntime().addEventHook( hook );
            return recv.getRuntime().getTrue();
        } else {
            return recv.getRuntime().getFalse();
        }
    }

}
