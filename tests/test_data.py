from hypothesis import given, assume
from hypothesis.strategies import *
from robber import expect
from utils import typesAndData

from bitstream_python import BitStream
from numpy import *

@given(typesAndData())
def test_all_types(data):
    """Reading and writing of any type works as expected"""

    stream = BitStream()

    # Write the data
    for typeinfo, list in data:
        stream.write(list, typeinfo, len(list))

    # Read the data back out
    for typeinfo, list in data:
        read = stream.read(typeinfo, len(list))
        expect(read) == list

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
