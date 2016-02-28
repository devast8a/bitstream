from setuptools import setup
from Cython.Build import cythonize

setup(
    name           = 'bitstream_python',
    version        = '1.0',
    description    = 'Stream that operates on the bit level',
    author         = 'devast8a',
    author_email   = 'devast8a@whitefirex.com',
    ext_modules    = cythonize("bitstream_python/*.pyx"),
    packages       = ['bitstream_python'],
    setup_requires = ['pytest-runner'],
    tests_require  = ['pytest'],
)
