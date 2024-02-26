from setuptools import setup, find_packages

setup(name="screensystem",
      version="0.0.1",
      install_requires=["requests"],
      packages=find_packages(include=['screensystem','screensystem.*']),
      entry_points = {
        'console_scripts':['screensystem=screensystem.screensystem:main']
      }
      )
