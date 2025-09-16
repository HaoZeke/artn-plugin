
# Instruction for the Documentation


## Tools for the documentation

The code's documentation is made with Sphinx, a python module.
To be able to compile it locally you need the following python packages.
You can install them using the `pip` command:
```bash
python3 -m pip install numpy==1.26.4
python3 -m pip install six==1.16.0
python3 -m pip install sphinx==5.3.0
python3 -m pip install sphinx-rtd-theme==1.1.1
python3 -m pip install sphinx-sitemap==2.2.1
python3 -m pip install breathe==4.34.0
python3 -m pip install sphinx-fortran==1.1.1
python3 -m pip install sphinx-rtd-size==0.2.0
python3 -m pip install sphinx-design==0.6.1
```
to build the documentation, go into `artn-plugin/docs/` and write:
```bash
make html
```
Then the main page of the documentation is: `artn-plugin/docs/_build/html/index.html`


## Documentation Organisation 


The documentation files are organised by one rst file: `index.rst`.
It defines the tree of the documentation.
If you want to add a section in the manual it is in this file.

There is different level of documentation, the sections and the code description.
The code description are all in the folder `docs/src`, `docs/params` and `docs/interface/<engine>`.
Using these materials the documentation in folder `docs/sections` presente the code and the plugin and so on.



