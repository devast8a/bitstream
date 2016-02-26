# Use setuptools in order to monkeypatch support MSVC for Python
try:
    import setuptools.msvc9_support; setuptools.msvc9_support.patch_for_specialized_compiler()
except ImportError:
    pass
import pyximport; pyximport.install()
