import org.jruby.runtime.EventHook;


public abstract class RcovHook extends EventHook {

    /** returns true if the hook is set */
    abstract boolean isActive();
    
    /** used to mark the hook set or unset */
    abstract void setActive(boolean active);
}
