# bitstream
At the moment mostly a drop-in replacement for the [bitstream](https://pypi.python.org/pypi/bitstream/2.0.3) library.

The bitstream library was too slow for the purposes I needed it for, this library has better performance.
Specifically I wanted to scan along for a given sequence and then start decoding from there. bitstream isn't
designed to seek along, constantly saving and restoring state.

# Why?
1.  You want a nice interface for dealing with things at the bit level
2.  You need to seek along your data
3.  It needs to be relatively fast

# How?
```python
from bitstream_python import BitStream
from numpy import *

stream = BitStream()
stream.write(True, bool)
stream.write(0xFF, uint8)

assert(stream.read(bool, 9) == [True] * 9)

stream.write([1,0,1,0], bool, 4)
stream.write([1,0,1,1], bool, 4)
stream.write(0xCD, uint8)

assert(stream.read(uint16) == 0xABCD)
```

Write one thing `stream.write(value, type)`

Read one thing `stream.read(type)`

Write many things `stream.write([value, value, ...], type, length)`

Read many things `stream.read(type, length)`

# Dependencies
To run:
* numpy

To build/install:
* Cython
* numpy

To test:
* Cython
* numpy
* py.test
* hypothesis
* robber

# Installing
1. Install required dependencies
2. Run `$ python setup.py install`

# Testing
1. Install required dependencies
2. Run `$ python setup.py install test`

# License
Licensed under the MIT License, refer to LICENSE.md for more information.
