
# Instruction for the Documentation


## Tools for the documentation

The code's documentation is made with Sphinx, a python module.
To be able to compile it locally you need:
- sphinx
- sphinx-rtd-theme
- sphinx-sitemap
- sphinx-fortran
- breathe
You can install them using the `pip` command:
```bash
$ pip install sphinx...
```
Once your python environment ready you can build the documentation going in the folder `artn-plugin/docs/` and writing the cammand:
```bash
make html
```
Then the documentation is in folder: `artn-plugin/docs/_build/html/index.html`


## Documentation Organisation 


The documentation files are organised by one rst file: `index.rst`.
It defines the tree of the documentation.
If you want to add a section in the manual it is in this file.

There is different level of documentation, the sections and the code description.
The code description are all in the folder `docs/src`, `docs/params` and `docs/interface/<engine>`.
Using these materials the documentation in folder `docs/sections` presente the code and the plugin and so on.



