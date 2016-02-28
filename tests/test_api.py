from hypothesis import given, assume
from hypothesis.strategies import *
from robber import expect
from utils import typesAndData

from bitstream_python import BitStream
from numpy import *

uint8_list = lists(integers(0, 0xFF))

@given(uint8_list)
def test_read(data):
    """Read with no length specified returns the object directly"""
    assume(data)

    stream = BitStream()
    for item in data:
        stream.write(item, uint8)
        expect(stream.read(uint8)) == item

@given(uint8_list)
def test_read_length(data):
    """Read with a length specified returns the type wrapped in an array-like"""
    assume(data)

    stream = BitStream()
    for item in data:
        stream.write(item, uint8)
        expect(stream.read(uint8, 1)) == [item]

@given(uint8_list)
def test_write_array(data):
    """Write an array of data to the stream"""
    assume(data)

    stream = BitStream()
    stream.write(data, uint8, len(data))
    read = stream.read(uint8, len(data))

    expect(read) == data

@given(uint8_list)
def test_seek(data):
    """seekTo moves our read pointer up to the specified item"""
    assume(data)

    stream = BitStream()
    stream.write(data, uint8, len(data))

    stream.seekTo([data[-1]])
    expect(stream.read(uint8)) == data[-1]
