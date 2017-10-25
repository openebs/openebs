OpenEBS Documentation : http://openebs.readthedocs.io/en/latest/

Automated builds, setup for OpenEBS documentation are at : https://readthedocs.org/projects/openebs/

Sphinx is used for building the OpenEBS documentation.  http://www.sphinx-doc.org/en/stable/tutorial.html

## Contributing to Documentation

Documentation Content is located under *documentation/source* in reStructured (rst) files. **documentation/source/index.rst** contains the high level documentation structure (Table of Contents), which links to the content provided in other rst files either in the same directory or in child directories. 

Before editing the files, familiarize yourself with the [reStructured markup](http://www.sphinx-doc.org/en/stable/rest.html#rst-primer). 

After you are done with your edits, you can use the below steps to build locally. On committing to the master branch, an automatic build will be triggered and the documentation will be available at the live site.

## Manual or Local Build instructions

To build the documentation on your local machine, you will require Python 2.7 or latest and Sphinx
```
pip install Sphinx
pip install sphinx_rtd_theme
```

### Build
```
git clone  https://github.com/openebs/openebs.git
cd openebs/documentation
make html
```

### Verify 

The html documentation is generated under the "build/html" directory. Open the index.html in your browser. 

