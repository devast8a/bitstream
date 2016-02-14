import cython
import numpy

DEF UNIT_SIZE_IN_BITS = 8

ctypedef signed char int8
ctypedef unsigned char uint8
ctypedef signed short int16
ctypedef unsigned short uint16
ctypedef signed int int32
ctypedef unsigned int uint32
ctypedef signed long long int64
ctypedef unsigned long long uint64

cdef class State:
    def __init__(State self, BitStream stream):
        self.offsetRead = stream.offsetRead
        self.offsetReadBit = stream.offsetReadBit
        self.offsetWrite = stream.offsetWrite
        self.stream = stream

    cdef BitStream stream
    cdef int64 offsetRead
    cdef int64 offsetReadBit
    cdef int64 offsetWrite
    cdef int64 offsetWriteBit

cdef class BitStream:
    cdef dict database
    cdef list stream

    cdef int64 offsetRead
    cdef int64 offsetReadBit
    cdef int64 offsetWrite
    cdef int64 offsetWriteBit

    def __init__(self):
        self.stream = []
        self.database = defaultFactory.database

        self.offsetRead = 0
        self.offsetReadBit = 0
        self.offsetWrite = 0
        self.offsetWriteBit = 0

    cpdef write(BitStream self, value, type key):
        cdef TypeInfo typeinfo = self.database[key]
        cdef validator = typeinfo.validator

        if validator and not validator(value):
            raise Exception("Input did not validate")

        # Advance pointers
        self.offsetWriteBit += typeinfo.length
        self.offsetWrite    += self.offsetWriteBit / UNIT_SIZE_IN_BITS
        self.offsetWriteBit  = self.offsetWriteBit % UNIT_SIZE_IN_BITS

        self.stream.append(value)

    cpdef list read(BitStream self, type key, int length):
        cdef TypeInfo typeinfo = self.database[key]

        output = []
        for i in range(length):
            # TODO: Check for buffer overruns
            output.append(typeinfo.reader(self))

            # Advance pointers
            self.offsetReadBit += typeinfo.length
            self.offsetRead    += self.offsetReadBit / UNIT_SIZE_IN_BITS
            self.offsetReadBit  = self.offsetReadBit % UNIT_SIZE_IN_BITS

        return output

    cpdef State save(BitStream self):
        return State(self)

    cpdef void restore(BitStream self, State state):
        if state.stream != self:
            raise Exception("State is not registered to this input")

        self.offsetRead = state.offsetRead
        self.offsetReadBit = state.offsetReadBit
        self.offsetWrite = state.offsetWrite

cdef class TypeInfo:
    def __init__(
        TypeInfo self,
        object key,
        int32 length = -1,
        reader = None,
        validator = None,
        writer = None,
    ):
        self.key = key
        self.length = length
        self.reader = reader
        self.writer = writer
        self.validator = validator

    # Length of the type in bits
    cdef int32 length
    cdef validator
    cdef reader
    cdef writer
    cdef key

cdef class BitStreamFactory:
    cdef dict database

    def __init__(self):
        self.database = {}

    cpdef void register(BitStreamFactory self, TypeInfo typeinfo):
        self.database[typeinfo.key] = typeinfo
        return

cdef BitStreamFactory defaultFactory = BitStreamFactory()

cdef inrange(lower, upper):
    return lambda value: lower <= value <= upper

cdef read_uint8(BitStream stream):
    # If we're reading on the bit boundary, just read the current item
    if stream.offsetReadBit == 0:
        return stream.stream[stream.offsetRead]

cdef write_uint8(BitStream stream, value):
    return 0

cdef read_bool(BitStream stream):
    return (stream.stream[stream.offsetRead] >> (7 - stream.offsetReadBit)) & 0x01 > 0

cdef write_bool(BitStream stream, value):
    stream.stream[stream.offsetWrite] |= (stream.offsetWriteBit << value)

defaultFactory.register(TypeInfo(numpy.uint8,
    length=8,
    validator=inrange(0x00, 0xFF),
    reader=read_uint8,
    writer=write_uint8
))

defaultFactory.register(TypeInfo(bool,
    length=1,
    reader=read_bool,
    writer=write_bool
))
