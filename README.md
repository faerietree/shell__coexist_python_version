Coexisting alternate python version(s)
===

When to use it?
---
If a different python version needs to coexist, e.g. if it's required in other scripts, then this shell script will download, setup (altinstall) and provide the path to the altinstalled python binary, e.g. `PATH_TO_PYTHON=$HOME/lib/bin/python3.4`.

How to use it?
---
Make executable:

    chmod +x ~/shell__coexisting_alternate_python_version/download_setup_and_get_path_to.sh

If you need the newest available version, then just:

    cmd=`~/shell__coexisting_alternate_python_version/download_setup_and_get_path_to.sh`

Else if you need a certain version, e.g. 2.6 or 3.9, then you can just specify it like follows:

    PYTHON_VERSION_2DIGITS='2.6'  ~/shell__coexisting_alternate_python_version/download_setup_and_get_path_to.sh

Advanced usage (for rebuilding after e.g. enabling packages in `Python-<version>/Modules/Setup.dist`, e.g. like it's done for `zlib` or `_sha` packages (see the shell script as reference):
    REDOWNLOAD=0 REBUILD=1 PYTHON_VERSION_2DIGITS='3.3' ~/shell__coexisting_alternate_python_version/download_setup_and_get_path_to.sh


Then install missing packages, e.g. using:

    $PATH_TO_CUSTOM_VIRTUALENV/bin/pip install <package>

Currently the virtual environment not needs to be deactivated. If that is required at some time, then it may work similarly to activation:

    source /path/to/virtualenvironment_python<version_2digits>/bin/deactivate

*Note: The path to the custom virtualenv is output by this shell script.*


###Virtualenv
Provide VIRTUALENV=1 analogously if the returned path to the python executable shall lead to the virtualenv python.

Example for getting <a href="https://github.com/upverter/schematic-file-converter">schematic_file_converter</a> to work. 
---

    DEBUG=0 REDOWNLOAD=0 REBUILD=1 PYTHON_VERSION_2DIGITS='2.6' ~/shell__coexisting_alternate_python_version/download_setup_and_get_path_to.sh 
    ~/virtualpythonenvironment_python2.6/bin/pip install argparse
    cd ~/freetype-py/
    sudo ~/virtualpythonenvironment_python2.6/bin/python2.6 setup.py install
    ~/virtualpythonenvironment_python2.6/bin/pip install freetype
    ~/virtualpythonenvironment_python2.6/bin/pip install PIL
    ~/virtualpythonenvironment_python2.6/bin/python2.6 -m upconvert/upconverter --input ~/Elektronik/BMS/openBMS/PCB\ Design/bms3.sch --from Eagle --to KiCad --output ~/Elektronik/BMS/openBMS/bms3.sch
  

