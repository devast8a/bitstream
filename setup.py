from setuptools import setup
from Cython.Build import cythonize

import sys
from setuptools.command.test import test as TestCommand


# Perform testing without installing module, useful in development
class Test(TestCommand):
    def initialize_options(self):
        TestCommand.initialize_options(self)
        self.pytest_args = []

    def run_tests(self):
        #import here, cause outside the eggs aren't loaded
        import pytest

        # Use setuptools in order to monkeypatch MSVC for Python support
        try:
            import setuptools.msvc9_support; setuptools.msvc9_support.patch_for_specialized_compiler()
        except ImportError:
            pass
        import pyximport; pyximport.install()

        sys.exit(pytest.main(self.pytest_args))

setup(
    name         = 'bitstream_python',
    version      = '1.0',
    description  = 'Stream that operates on the bit level',
    author       = 'devast8a',
    author_email = 'devast8a@whitefirex.com',
    ext_modules  = cythonize("bitstream_python/*.pyx"),
    packages     = ['bitstream_python'],
    tests_require= ['pytest'],
    cmdclass     = {
        'test': Test
    },
)
