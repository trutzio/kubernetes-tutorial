# Configuration file for the Sphinx documentation builder.

# -- Project information

project = 'Kubernetes Tutorial'
copyright = '2026, Trutz Software Consulting GmbH'
author = 'Christian Trutz'

release = '0.1'
version = '0.1.0'

# -- General configuration

extensions = [
    'sphinx.ext.duration',
    'sphinx.ext.doctest',
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    'sphinx.ext.intersphinx',
]

intersphinx_mapping = {
    'python': ('https://docs.python.org/3/', None),
    'sphinx': ('https://www.sphinx-doc.org/en/master/', None),
}
intersphinx_disabled_domains = ['std']

templates_path = ['_templates']

# -- Options for HTML output

html_theme = 'sphinx_rtd_theme'


# https://docs.readthedocs.com/platform/stable/config-file/v2.html#formats
formats = 'all'
