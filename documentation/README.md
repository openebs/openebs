OpenEBS Documentation : http://openebs.readthedocs.io/en/latest/

Automated builds are setup for OpenEBS documentation are at : https://readthedocs.org/projects/openebs/

Sphinx is used for building the OpenEBS documentation.  http://www.sphinx-doc.org/en/stable/tutorial.html

## Contributing to Documentation

### Prerequisites
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

