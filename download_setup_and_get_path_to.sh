#!/bin/bash

TEMP='/tmp'

# http://serverfault.com/questions/607884/hide-the-output-of-a-shell-command-only-on-success
set -e

SILENT_LOG=$TEMP/silent_log_$$.txt
trap "/bin/rm -f $SILENT_LOG" EXIT

function report_and_exit {
    cat "${SILENT_LOG}";
    silent echo "\033[91mError running command.\033[39m"
    exit 1;
}

function silent {
	if [ -z $IS_DEBUG ] || [ $IS_DEBUG -le 0 ]; then
        $* 2>>"${SILENT_LOG}" >> "${SILENT_LOG}" || report_and_exit;
	else
		$*
	fi
}
#silent mkdir -v test

#
# INPUT
#
IS_DEBUG=$DEBUG
if [ -z $DEBUG ]; then
	IS_DEBUG=0
fi
silent echo 'Is debug enabled: '$IS_DEBUG  # Comes here because else it will ever be silent, i.e. always logged to the logfile in the temp folder.

silent echo 'Is redownload enabled: '$REDOWNLOAD
SHALL_REDOWNLOAD=$REDOWNLOAD
if [ -z $REDOWNLOAD ] && [ -z $SHALL_REDOWNLOAD ]; then
    SHALL_REDOWNLOAD=1 
	silent echo 'Defaulting to enabled (because an existing file my be broken/incomplete/truncated). (Set SHALL_REDOWNLOAD=0 to prevent redownload if file has been downloaded earlier.)'
fi
silent echo 'Is rebuild enabled: '$REBUILD
SHALL_REBUILD=$REBUILD
if [ -z $REBUILD ] && [ -z $SHALL_REBUILD ]; then
    SHALL_REBUILD=0
	silent echo 'Rebuilding deactivated by default. (set REBUILD=1 to activate)'
fi
silent echo 'Shall return path to virtualenv python: '$VIRTUALENVPYTHON
SHALL_RETURN_VIRTUALENVPYTHON=$VIRTUALENVPYTHON
if [ -z $VIRTUALENVPYTHON ] && [ -z $SHALL_RETURN_VIRTUALENVPYTHON ]; then
    SHALL_RETURN_VIRTUALENVPYTHON=0
	silent echo 'Returning virtualenv python path deactivated by default. (set VIRTUALENVPYTHON=1 to enable)'
fi


#
# MAIN PROGRAM
#
IS_PYTHON_VERSION_AUTOMATIC=0
if [ -z $PYTHON_VERSION_2DIGITS ]; then
	PYTHON_VERSION_2DIGITS='3' # TODO Keep up to date manually or figure highest available number by checking for wget result being valid.
	IS_PYTHON_VERSION_AUTOMATIC=1
fi


cd $TEMP

#result=`ls | grep 'Python-'$PYTHON_VERSION_2DIGITS'*.tgz'`
#result=`ls | grep 'Python-'$PYTHON_VERSION'.tgz'`
## 2> $TEMP/ls_error.txt
#if [[ $result = '' ]] || [[ -n $SHALL_REDOWNLOAD ]]; then
    silent echo 'Downloading python '$PYTHON_VERSION_2DIGITS':'
	
    if [ $IS_PYTHON_VERSION_AUTOMATIC -ne 0 ]; then
	    # Automatically figure highest available python version:
        second_last_digit=5
	    PYTHON_VERSION_2DIGITS=$PYTHON_VERSION_2DIGITS'.'
    else
        second_last_digit=''  #$(ls $PATH_TO_BLENDER_PYTHON_LIB | egrep -o '[0-9]+[.][[:digit:]]+' | head -n1)
    fi
	# Execute at least once.
	is_python_version_url_found=0
    while [[ $second_last_digit -ge 0 ]] || [[ $IS_PYTHON_VERSION_AUTOMATIC -ne 1 ]]; do
		silent echo '2nd last digit: '$second_last_digit
	    last_digit=9
		for ((last_digit=9; last_digit>=0; last_digit--)) {
        #while [[ $last_digit -ge 0 ]]; do
		    silent echo 'last digit: '$last_digit
	        PYTHON_VERSION=$PYTHON_VERSION_2DIGITS''$second_last_digit'.'$last_digit
			
            silent echo 'Trying to download '$PYTHON_VERSION':'
			
            #wget --server-response -q -o wgetOut https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
            #sleep 3
            #_wgetHttpCode=`cat wgetOut | gawk '/HTTP/{ print $2 }'`
            #if [ "$_wgetHttpCode" != "200" ]; then
            #    silent echo "[Error] `cat wgetOut`"
            #else
			ARCHIVE='Python-'$PYTHON_VERSION'.tgz'
            if [[ -f $ARCHIVE ]] && [[ $SHALL_REDOWNLOAD -ne 0 ]]; then
                if [[ -f $ARCHIVE'.1' ]]; then
					silent echo 'Removing '$ARCHIVE'.1 ...'
            	    rm $ARCHIVE'.1'
				    silent echo '*done*'
				fi
				silent echo 'Removing '$ARCHIVE' ...'
            	rm $ARCHIVE
				silent echo '*done*'
            fi
            if [[ -f $ARCHIVE ]] || wget -q https://www.python.org/ftp/python/$PYTHON_VERSION/$ARCHIVE; then
	        #silent echo $r # captured string output
		    #silent echo $? # return value.
 	   	    #if [ $? -ge 1 ]; then # -O python.tgz; then # if != 0 then it's an error, 2 is severe error.
			    #silent echo 'Version '$PYTHON_VERSION' could not be found.'
			    silent echo 'Found version '$PYTHON_VERSION'.'
                if [ $IS_PYTHON_VERSION_AUTOMATIC -ne 0 ]; then
				    PYTHON_VERSION_2DIGITS=$PYTHON_VERSION_2DIGITS'.'$second_last_digit
				fi
				is_python_version_url_found=1
			    break
			#else
		    #    last_digitia-- 
		    fi
			#silent echo 'last digit: '$last_digit
		#done
	    }
		silent echo 'second last digit: '$second_last_digit
		# Version was already found?
		#if [ $? -ne 0 ]; then
		if [ $is_python_version_url_found -le 0 ]; then
			silent echo 'No version found to this major version: '$PYTHON_VERSION_2DIGITS''$second_last_digit
		else
			silent echo 'Found version '$PYTHON_VERSION'.'
		    break
		fi
		# Continue with a different next 2nd last digit or terminate?
        if [ $IS_PYTHON_VERSION_AUTOMATIC -ne 0 ]; then
		    # Automatically figure highest available python version:
		    (( second_last_digit-- ))
		else
			silent echo 'Did not find the correct python version URL and are not in automatic mode.'
			break
		fi
    done
	
#fi

cd $HOME 
if ! [[ -d 'Python-'$PYTHON_VERSION ]]; then
    silent echo 'Unpacking ...'
    tar xzf $TEMP'/'$ARCHIVE
    silent echo '*done*'
fi

PATH_TO_ALTINSTALL=$HOME/lib/
if ! [[ -d $PATH_TO_ALTINSTALL ]]; then
    mkdir $PATH_TO_ALTINSTALL
fi
PATH_TO_PYTHON=$PATH_TO_ALTINSTALL'/bin/python'$PYTHON_VERSION_2DIGITS
if [ ! -f $PATH_TO_PYTHON ] || [ $SHALL_REBUILD -ne 0 ]; then
    silent echo 'Building python in directory ./Python-'$PYTHON_VERSION
    cd './Python-'$PYTHON_VERSION
    #pwd
	silent echo 'Using prefix:'$PATH_TO_ALTINSTALL
	silent ls
	
	# To compile with zlib support: following amazing asanadi: 
	# http://stackoverflow.com/questions/12344970/building-python-from-source-with-zlib-support
	MAKEFILE='Modules/Setup'
	if [[ ! -f $MAKEFILE ]]; then
	    cp Modules/Setup.dist Modules/Setup
	fi
	find . -type f -samefile $MAKEFILE -exec sed -i 's/^[#]zlib/zlib/' {} \;
	cd Modules/zlib
	silent echo 'Building zlib ...'
	silent ./configure --prefix=$PATH_TO_ALTINSTALL
	silent make
	silent make install
	silent echo '*done*'
    cd ../..

	silent echo 'Enabling _sha packages ...'
	find . -type f -samefile $MAKEFILE -exec sed -i 's/^[#]_sha/_sha/' {} \;
	#cd Modules/_sha256 not required as has no subfolder in Modules.
	silent echo '*done*'
    #cd ../..
	
	silent echo 'Enabling socket module for schematic file converter et alia ...'
	find . -type f -samefile $MAKEFILE -exec sed -i 's/^[#]_socket/_socket/' {} \;
	find . -type f -samefile $MAKEFILE -exec sed -i 's/^[#]SSL/SSL/' {} \;
	find . -type f -samefile $MAKEFILE -exec sed -i 's/^[#]_ssl/_ssl/' {} \;
	find . -type f -samefile $MAKEFILE -exec sed -i 's/^[#][\t ]*-DUSE_SSL/   -DUSE_SSL/' {} \;
	find . -type f -samefile $MAKEFILE -exec sed -i 's/^[#][\t ]*-L[$][(]SSL/   -L$(SSL/' {} \;
	
	
	
	
	silent ./configure --prefix=$PATH_TO_ALTINSTALL
	#make
	silent make altinstall
	#silent echo '*done*'
    #silent echo '-----------------'
	
    silent echo 'Using python altinstall binary '$PATH_TO_PYTHON' for the following library builds.'
	
fi


# To allow to install missing packages easily using 'pip'.
VIRTUALENV='virtualenv-1.9.1'
ARCHIVE=$VIRTUALENV'.tar.gz'
if [[ -f $ARCHIVE ]] && [[ $SHALL_REDOWNLOAD -ne 0 ]]; then
	rm $ARCHIVE
fi
if [[ ! -f $ARCHIVE ]]; then
    silent echo 'Downloading virtualenv ...'
    wget -q http://pypi.python.org/packages/source/v/virtualenv/$ARCHIVE
    silent echo '*done*'
fi
if ! [[ -d $VIRTUALENV ]]; then
    silent echo 'Unpacking ...'
    tar zxf $ARCHIVE
    silent echo '*done*'
fi

cd $VIRTUALENV 
silent echo 'Setting up virtualenv ...'
silent $PATH_TO_PYTHON setup.py install
silent echo '*done*'

PATH_TO_CUSTOM_VIRTUALENV=$HOME'/virtualpythonenvironment_python'$PYTHON_VERSION_2DIGITS
if [[ ! -d $PATH_TO_CUSTOM_VIRTUALENV ]]; then
    mkdir $PATH_TO_CUSTOM_VIRTUALENV
	#rm $PATH_TO_CUSTOM_VIRTUALENV -r
fi

silent echo 'Creating virtualenv in '$PATH_TO_CUSTOM_VIRTUALENV' ...'
silent $PATH_TO_ALTINSTALL'/bin/virtualenv' $PATH_TO_CUSTOM_VIRTUALENV --python $PATH_TO_PYTHON
silent echo 'Activating virtualenv (deactive after use via "source '$PATH_TO_CUSTOM_VIRTUALENV'/deactivate") ...'
source $PATH_TO_CUSTOM_VIRTUALENV/bin/activate


# If it's not complaining of missing packages in the altinstall lib/<pythonversion>/site-packages/, then install missing packages. 
#~/shell__kx/kx install pip
#$PATH_TO_CUSTOM_VIRTUALENV/bin/pip install <package>


# Deactivating the virtual environment after use not foreseen or required? (file not exists)
#source $PATH_TO_CUSTOM_VIRTUALENV/bin/deactivate


if [[ $SHALL_RETURN_VIRTUALENVPYTHON -ne 0 ]]; then
    echo $PATH_TO_CUSTOM_VIRTUALENV/bin/python$PYTHON_VERSION_2DIGITS
else
    echo $PATH_TO_PYTHON
fi

