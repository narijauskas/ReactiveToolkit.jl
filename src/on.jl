
#------------------------------------ ConditionTrigger ------------------------------------#


#------------------------------------ on macro ------------------------------------#

macro on(args...)
    _on(args...)
end

_on(x, loop)              = _on(x, "@on $x", :(), loop, :())
_on(x, init, loop, final) = _on(x, "@on $x", init, loop, final)
_on(x, name, loop)        = _on(x, name, :(), loop, :())

function _on(x, name, init, loop, final)
    quote
        # cond = Threads.Condition()
        # link!($(esc(x)), cond) # x can be any iterable of topics
        trig = ConditionTrigger($(esc(x)).cond)
        @loop $(esc(name)) trig $(esc(init)) $(esc(loop)) $(esc(final))
    end
end


#------------------------------------ echo------------------------------------#

echo(x::AbstractTopic) = @on x "echo $(x.name)" println(x.name, ": ", x[])




