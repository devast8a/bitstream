from hypothesis import given, assume
from hypothesis.strategies import *
from robber import expect

from bitstream_python import BitStream
from numpy import *

@composite
def typesAndData(draw):
    """Test all implementations of """
    types = [
        # (type, generator)
        (bool, booleans()),
        (uint8, integers(0, 0xFF)),
        (uint16, integers(0, 0xFFFF))
    ]

    # Create a strategy that will generate a random data with a
    #   random type for us to use.
    random_type = sampled_from(types)

    # Actually generate a list of tests to perform
    tests = draw(lists(random_type))

    output = []
    for typeinfo, generator in tests:
        data = draw(lists(generator))
        output.append((typeinfo, data))
    return output
