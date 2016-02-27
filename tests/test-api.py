from hypothesis import given, assume
from hypothesis.strategies import *
from robber import expect

from bitstream_python import BitStream
from numpy import *

@given(lists(booleans()))
def test_bits(data):
    """Reading and writing arrays of booleans"""

    stream = BitStream()
    stream.write(data, bool, len(data))
    read = stream.read(bool, len(data))

    expect(read) == data

@given(lists(integers(0, 0xFF)))
def test_arrays(data):
    """Reading and writing arrays of uint8s"""

    stream = BitStream()
    stream.write(data, uint8, len(data))
    read = stream.read(uint8, len(data))

    expect(read) == data

def test_length():
    """Read with a length of 1 specified returns the type wrapped in an array-like"""

    stream = BitStream()
    stream.write(0xFF, uint8)
    assert(stream.read(uint8, 1) == [0xFF])

def test_no_length():
    """Read with no length specified returns the object directly"""

    stream = BitStream()
    stream.write(0xFF, uint8)
    assert(stream.read(uint8) == 0xFF)

@given(lists(integers(0, 0xFF)))
def test_seek(data):
    """seekTo moves our read pointer up to the specified item"""
    assume(data)

    stream = BitStream()
    stream.write(data, uint8, len(data))

    stream.seekTo([data[-1]])
    expect(stream.read(uint8)) == data[-1]
