from bitstream import BitStream
import pyximport; pyximport.install()
from bs import BitStream as BitStream2
from numpy import *

NUMBER = 200000

def test_read_write(stream):
    global NUMBER
    for i in range(NUMBER):
        stream.write(0xAA, uint8)
        stream.write(0xCC, uint8)
        stream.read(uint8, 1)
        stream.read(uint8, 1)

    stream.write(0xAA, uint8)
    stream.write(0xCC, uint8)

    assert(stream.read(bool,8) == [True, False, True, False, True, False, True, False])
    assert(stream.read(uint8,1) == [0xCC])

def test_state(stream):
    global NUMBER

    for i in range(NUMBER):
        stream.write(0xAA, uint8)

    for i in range(NUMBER):
        state = stream.save()
        stream.read(uint8, 8)
        stream.restore(state)

def test_offset(stream):
    stream.write(0b11001010, uint8)
    stream.write(True, bool)

    assert(stream.read(bool, 1) == [True])
    assert(stream.read(uint8, 1) == [0b10010101])

def test_state(stream):
    global NUMBER

    for i in range(NUMBER):
        stream.write(0xAA, uint8)

    for i in range(NUMBER):
        state = stream.save()
        stream.read(uint8, 8)
        stream.restore(state)

def run_tests():
    import timeit

    g = globals()
    for name in g:
        if name.startswith('test_'):
            time1 = timeit.timeit("%s(BitStream())" % name, setup="from __main__ import %s, BitStream" % name, number=1)
            time2 = timeit.timeit("%s(BitStream2())" % name, setup="from __main__ import %s, BitStream2" % name, number=1)
            print "%20s  %2.4f  %2.4f" % (name, time1, time2)

if __name__ == '__main__':
    run_tests()
