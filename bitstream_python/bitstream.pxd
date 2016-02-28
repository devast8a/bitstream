ctypedef signed char int8
ctypedef unsigned char uint8
ctypedef signed short int16
ctypedef unsigned short uint16
ctypedef signed int int32
ctypedef unsigned int uint32
ctypedef signed long long int64
ctypedef unsigned long long uint64

cdef class State:
    cdef BitStream stream
    cdef int64 offsetRead
    cdef int64 offsetWrite

cdef class BitStream:
    cdef dict database
    cdef list stream

    cdef int64 offsetRead
    cdef int64 offsetWrite

    cpdef write(BitStream self, value, type key, int64 count=?)
    cpdef read(BitStream self, type key, int64 count=?)
    cpdef readInt(BitStream self, int size, int count=?)

    cpdef void seek(BitStream self, int64 offset)
    cpdef seekTo(BitStream self, list searchFor)

    cpdef State save(BitStream self)
    cpdef void restore(BitStream self, State state)

cdef class TypeInfo:
    cdef int32 length
    cdef validator
    cdef reader
    cdef writer
    cdef key

cdef class BitStreamFactory:
    cdef dict database
    cpdef void register(BitStreamFactory self, TypeInfo typeinfo)

cdef BitStreamFactory defaultFactory = BitStreamFactory()
