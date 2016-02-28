from hypothesis import given, assume
from hypothesis.strategies import *
from pytest import raises
from robber import expect

from bitstream_python import BitStream, ReadError, WriteError
from numpy import *

t_uint8 = integers(0, 2**8-1)
t_int32 = integers(-2**31 + 1, 2**31-1)

@given(lists(t_uint8), t_int32)
def test_write_count(data, length):
    """write throws errors when invalid count is given"""
    assume(not(0 <= length <= len(data)))

    with raises(WriteError):
        stream = BitStream()
        stream.write(data, uint8, length)

@given(lists(t_uint8), t_int32)
def test_read_count(data, length):
    """read throws errors when invalid count is given"""
    assume(not(0 <= length <= len(data)))

    with raises(ReadError):
        stream = BitStream()
        stream.write(data, uint8, len(data))
        stream.read(uint8, length)
