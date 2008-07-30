import org.jruby.runtime.EventHook;


public interface RcovHook extends EventHook {

    /** returns true if the hook is set */
    boolean isActive();
    
    /** used to mark the hook set or unset */
    void setActive(boolean active);
}
