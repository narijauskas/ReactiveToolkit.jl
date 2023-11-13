# Future
more complete UDP support -> needs a generic serialization scheme for marshalling/unmarshalling

rework the task killing mechanism to be simpler, more extensible

color customizations?


launching other terminals (this may be too system-specific to be worth it)
piping between terminals and julia instances
will most likely be built on top of UDP


default values for topics
topics must always have a value - this will not change.
eltype(topic::Topic{T}) = T
In practice, a "no value" state creates too many downstream problems when tasks assume topic[] will return a value of type T for topics of type Topic{T}.