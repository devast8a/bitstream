import pyximport; pyximport.install()
from bitstream import BitStream
from numpy import *
from bitstream_python.bitstream import BitStream as BitStream2

NUMBER = 200000

def conv_test(stream, inValue, inType, inSize, outValue, outType, outSize):
    # Make sure it's working as expected, don't
    #  compare inside the loops to avoid measuring
    #  array comparison differences.
    for i in range(int(math.ceil((float(outSize) / inSize)))):
        stream.write(inValue, inType)

    assert(stream.read(outType, 1) == [outValue])

    # Do it over and over again to test performance
    for i in range(NUMBER * outSize / 8):
        stream.write(inValue, inType)

    for i in range(NUMBER * inSize / 8):
        stream.read(outType, 1)

def test_conv_u8_bits(stream):
    """Test writing one type and reading another (uint8 -> bitfield)"""

    for i in range(NUMBER):
        stream.write(0xAA, uint8)
        stream.read(bool, 8)

def test_conv_bits_u8(stream):
    """Test writing one type and reading another (bitfield -> uint8)"""

    for i in range(NUMBER):
        stream.write(True, bool)
        stream.write(False, bool)
        stream.write(True, bool)
        stream.write(False, bool)
        stream.write(True, bool)
        stream.write(False, bool)
        stream.write(True, bool)
        stream.write(False, bool)

        stream.read(uint8,1)

def test_conv_u8_u16(stream):
    """Test writing one type and reading another (uint8 -> uint16)"""
    conv_test(stream, 0xAB, uint8, 8, 0xABAB, uint16, 16)

def test_conv_u16_u8(stream):
    """Test writing one type and reading another (uint16 -> uint8)"""
    conv_test(stream, 0xABCD, uint16, 16, 0xAB, uint8, 8)

def test_offset(stream):
    """Reads and writes on non-byte-aligned boundary correctly"""

    stream.write(0b11001010, uint8)
    stream.write(True, bool)

    assert(stream.read(bool, 1) == [True])
    value = stream.read(uint8, 1)
    assert(value == [0b10010101])

def test_state_aligned(stream):
    """recovers saved state correctly"""

    for i in range(NUMBER):
        stream.write(0xAA, uint8)

    for i in range(NUMBER):
        state = stream.save()
        assert(stream.read(uint8, 1) == [0xAA])
        stream.restore(state)

def test_state_unaligned(stream):
    """recovers saved state on a non-byte-aligned boundary correctly"""
    stream.write(0b11001010, uint8)
    stream.write(True, bool)
    assert(stream.read(bool, 1) == [True])

    for i in range(NUMBER):
        state = stream.save()
        value = stream.read(uint8, 1)
        assert(value == [0b10010101])
        stream.restore(state)

def test_underrun(stream):
    """Detects and resets to a known good state when more data is being read than written"""
    try:
        stream.write(0xFF, uint8)
        stream.read(uint8, 1)
        stream.read(uint8, 1)
    except Exception as e:
        stream.write(0xAA, uint8)
        assert(stream.read(uint8, 1) == [0xAA])

def scanning(stream, number):
    for i in range(number):
        stream.write(0xFF, uint8)

    for i in range(number):
        stream.read(bool)

        state = stream.save()
        assert(stream.read(uint8, 1) == [0xFF])
        assert(stream.read(uint16, 1) == [0xFFFF])
        stream.restore(state)

def test_scanning_large(stream):
    """Scan along the bitstream one bit at a time, reading various types (large data set)"""
    scanning(stream, NUMBER / 10)

def test_scanning_small(stream):
    """Scan along the bitstream one bit at a time, reading various types (small data set)"""
    scanning(stream, NUMBER / 100)

def perf_test(stream, value, type, unaligned):
    # Make sure it's working as expected, don't
    #  compare inside the loops to avoid measuring
    #  array comparison differences.
    if unaligned:
        stream.write(True, bool)

    stream.write(value, type)

    # Do it over and over again to test performance
    for i in range(NUMBER):
        stream.write(value, type)

    if unaligned:
        stream.read(bool)

    assert(stream.read(type, 1) == [value])
    for i in range(NUMBER):
        stream.read(type)

def test_pA_u8(stream):
    """Read and write, Aligned, uint8"""
    perf_test(stream, 0xAA, uint8, False)

def test_pA_u16(stream):
    """Read and write, Aligned, uint16"""
    perf_test(stream, 0xAAAA, uint16, False)

def test_pU_u8(stream):
    """Read and write, Unaligned, uint8"""
    perf_test(stream, 0xAA, uint8, True)

def test_pU_u16(stream):
    """Read and write, Unaligned, uint16"""
    perf_test(stream, 0xAAAA, uint16, True)

def test_pX_bool(stream):
    """Read and write, bool (Alignment does not matter)"""
    perf_test(stream, True, bool, False)

def test_api_nolength(stream):
    """Test that read with no length specified returns the type directly"""

    for i in range(NUMBER):
        stream.write(0xFF, uint8)
        v = stream.read(uint8)
        assert(v == 0xFF)

def test_api_length(stream):
    """Test that read with a length of 1 specified returns the type wrapped in an array-like"""

    for i in range(NUMBER):
        stream.write(0xFF, uint8)
        v = stream.read(uint8, 1)
        assert(v == [0xFF])


def run_tests():
    import timeit

    g = globals()
    print "%20s  %8s  %8s" % ("Test", "Old", "New")
    keys = g.keys()
    keys.sort()
    for name in keys:
        if name.startswith('test_'):
            time1 = timeit.timeit("%s(BitStream())" % name, setup="from __main__ import %s, BitStream" % name, number=1)
            time2 = timeit.timeit("%s(BitStream2())" % name, setup="from __main__ import %s, BitStream2" % name, number=1)
            print "%20s  %7.4fs  %7.4fs  %4d%%  %s" % (name, time1, time2, (time2*100)/time1, g[name].__doc__)

if __name__ == '__main__':
    run_tests()
