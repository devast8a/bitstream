from bitstream cimport *
import numpy

cdef int64 UNIT_SIZE = 8
cdef int64 UNIT_OFFSET = UNIT_SIZE - 1

# This file adds support for numpy types to bitstream-python
cdef inrange(lower, upper):
    return lambda value: lower <= value <= upper

cdef read_uint8(BitStream stream, int64 byte, int64 bit):
    # If we're reading on the bit boundary, just read the current item
    if bit == 0:
        return stream.stream[byte]

    # We want to read the remaining bits in the first byte,
    #  and the first (8 - remaining) bits in the last byte.
    return (((stream.stream[byte] << bit) & 0xFF) |
            ((stream.stream[byte + 1] >> (UNIT_SIZE - bit)) & 0xFF))

cdef write_uint8(BitStream stream, value, int64 byte, int64 bit):
    if bit == 0:
        stream.stream.append(value)
    else:
        stream.stream[byte] |= (value >> bit) & 0xFF
        stream.stream.append((value << (UNIT_SIZE - bit)) & 0xFF)

defaultFactory.register(TypeInfo(numpy.uint8,
    length=8,
    validator=inrange(0x00, 0xFF),
    reader=read_uint8,
    writer=write_uint8
))

cdef write_uint16(BitStream stream, value, int64 byte, int64 bit):
    write_uint8(stream, (value >> 8) & 0xFF, byte, bit)
    write_uint8(stream, value & 0xFF, byte + 1, bit)

cdef read_uint16(BitStream stream, int64 byte, int64 bit):
    return ((read_uint8(stream, byte, bit) << 8) |
        read_uint8(stream, byte + 1, bit))

defaultFactory.register(TypeInfo(numpy.uint16,
    length=16,
    validator=inrange(0x0000, 0xFFFF),
    reader=read_uint16,
    writer=write_uint16
))
