import os

def build(t):
	"""Build a .pyx file"""
	from pyximport.pyxbuild import pyx_to_dll
	from pathlib import Path
	t = Path(pyx_to_dll(t))
	os.remove(t.parent.parent.parent / t.name)
	t.rename(t.parent.parent.parent / t.name)
