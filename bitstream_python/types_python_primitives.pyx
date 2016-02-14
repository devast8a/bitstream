# Add support to bitstream for python primitive types
from bitstream cimport *

cdef int64 UNIT_SIZE = 8
cdef int64 UNIT_OFFSET = UNIT_SIZE - 1

cdef read_bool(BitStream stream, int64 byte, int64 bit):
    return (stream.stream[byte] >> (UNIT_OFFSET - bit)) & 0x01 > 0

cdef write_bool(BitStream stream, value, int64 byte, int64 bit):
    if bit == 0:
        stream.stream.append(0)

    stream.stream[byte] |= (value << (UNIT_OFFSET - bit))

defaultFactory.register(TypeInfo(bool,
    length=1,
    reader=read_bool,
    writer=write_bool
))
