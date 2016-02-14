import pyximport; pyximport.install()
import struct
from src.bitstream import BitStream
from numpy import *

NUMBER = 1000 * 1000

d1 = "\x01\x01" * NUMBER * 4
d2 = [0xFF] * NUMBER

def a1():
    for i in range(NUMBER):
        data = struct.unpack_from("8B", d1, i)
        assert(
            data[0] == True and
            data[1] == True and
            data[2] == True and
            data[3] == True and
            data[4] == True and
            data[5] == True and
            data[6] == True and
            data[7] == True
        )

        assert(
            data[0] == True and
            data[1] == True and
            data[2] == True and
            data[3] == True and
            data[4] == True and
            data[5] == True and
            data[6] == True and
            data[7] == True
        )

def a2():
    stream = BitStream(d2)

    for i in range(NUMBER):
        stream.seek(1)
        state = stream.save()
        value = stream.read(uint8, 1)
        assert(value == 0xFF)
        assert(value == 0xFF)
        stream.restore(state)

if __name__ == "__main__":
    import timeit
    print timeit.timeit("a1()", setup="from __main__ import a1", number=1)
    print timeit.timeit("a2()", setup="from __main__ import a2", number=1)
