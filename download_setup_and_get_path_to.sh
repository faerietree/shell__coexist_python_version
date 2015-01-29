#!/bin/bash
echo 'Is redownload enabled: '$REDOWNLOAD
SHALL_REDOWNLOAD=$REDOWNLOAD
if [ -z $REDOWNLOAD ] && [ -z $SHALL_REDOWNLOAD ]; then
    SHALL_REDOWNLOAD=1 
	echo 'Defaulting to enabled (because an existing file my be broken/incomplete/truncated).'
fi
echo 'Is rebuild enabled: '$REBUILD
SHALL_REBUILD=$REBUILD
if [ -z $REBUILD ] && [ -z $SHALL_REBUILD ]; then
    SHALL_REBUILD=0
	echo 'Rebuilding deactivated by default.'
fi

IS_PYTHON_VERSION_AUTOMATIC=0
if [ -z $PYTHON_VERSION_2DIGITS ]; then
	PYTHON_VERSION_2DIGITS='3' # TODO Keep up to date manually or figure highest available number by checking for wget result being valid.
	IS_PYTHON_VERSION_AUTOMATIC=1
fi

TEMP='/tmp'

# http://serverfault.com/questions/607884/hide-the-output-of-a-shell-command-only-on-success
set -e

SILENT_LOG=$TEMP/silent_log_$$.txt
trap "/bin/rm -f $SILENT_LOG" EXIT

function report_and_exit {
    cat "${SILENT_LOG}";
    echo "\033[91mError running command.\033[39m"
    exit 1;
}

function silent {
	#if [ -z $IS_DEBUG ] || [ $IS_DEBUG -le 0 ]; then
        $* 2>>"${SILENT_LOG}" >> "${SILENT_LOG}" || report_and_exit;
	#else
	#	$*
	#fi
}
#silent mkdir -v test

cd $TEMP

#result=`ls | grep 'Python-'$PYTHON_VERSION_2DIGITS'*.tgz'`
#result=`ls | grep 'Python-'$PYTHON_VERSION'.tgz'`
## 2> $TEMP/ls_error.txt
#if [[ $result = '' ]] || [[ -n $SHALL_REDOWNLOAD ]]; then
    echo 'Downloading python '$PYTHON_VERSION_2DIGITS':'
	
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
		echo '2nd last digit: '$second_last_digit
	    last_digit=9
		for ((last_digit=9; last_digit>=0; last_digit--)) {
        #while [[ $last_digit -ge 0 ]]; do
		    echo 'last digit: '$last_digit
	        PYTHON_VERSION=$PYTHON_VERSION_2DIGITS''$second_last_digit'.'$last_digit
			
            echo 'Trying to download '$PYTHON_VERSION':'
			
            #wget --server-response -q -o wgetOut https://www.python.org/ftp/python/$PYTHON_VERSION/Python-$PYTHON_VERSION.tgz
            #sleep 3
            #_wgetHttpCode=`cat wgetOut | gawk '/HTTP/{ print $2 }'`
            #if [ "$_wgetHttpCode" != "200" ]; then
            #    echo "[Error] `cat wgetOut`"
            #else
			ARCHIVE='Python-'$PYTHON_VERSION'.tgz'
            if [[ -f $ARCHIVE ]] && [[ $SHALL_REDOWNLOAD -ne 0 ]]; then
                if [[ -f $ARCHIVE'.1' ]]; then
					echo 'Removing '$ARCHIVE'.1 ...'
            	    rm $ARCHIVE'.1'
				    echo '*done*'
				fi
				echo 'Removing '$ARCHIVE' ...'
            	rm $ARCHIVE
				echo '*done*'
            fi
            if [[ -f $ARCHIVE ]] || wget https://www.python.org/ftp/python/$PYTHON_VERSION/$ARCHIVE; then
	        #echo $r # captured string output
		    #echo $? # return value.
 	   	    #if [ $? -ge 1 ]; then # -O python.tgz; then # if != 0 then it's an error, 2 is severe error.
			    #echo 'Version '$PYTHON_VERSION' could not be found.'
			    echo 'Found version '$PYTHON_VERSION'.'
                if [ $IS_PYTHON_VERSION_AUTOMATIC -ne 0 ]; then
				    PYTHON_VERSION_2DIGITS=$PYTHON_VERSION_2DIGITS'.'$second_last_digit
				fi
				is_python_version_url_found=1
			    break
			#else
		    #    last_digitia-- 
		    fi
			#echo 'last digit: '$last_digit
		#done
	    }
		echo 'second last digit: '$second_last_digit
		# Version was already found?
		#if [ $? -ne 0 ]; then
		if [ $is_python_version_url_found -le 0 ]; then
			echo 'No version found to this major version: '$PYTHON_VERSION_2DIGITS''$second_last_digit
		else
			echo 'Found version '$PYTHON_VERSION'.'
		    break
		fi
		# Continue with a different next 2nd last digit or terminate?
        if [ $IS_PYTHON_VERSION_AUTOMATIC -ne 0 ]; then
		    # Automatically figure highest available python version:
		    (( second_last_digit-- ))
		else
			echo 'Did not find the correct python version URL and are not in automatic mode.'
			break
		fi
    done
	
#fi

cd $HOME 
if ! [[ -d 'Python-'$PYTHON_VERSION ]]; then
    echo 'Unpacking ...'
    tar xzf $TEMP'/'$ARCHIVE
    echo '*done*'
fi

PATH_TO_ALTINSTALL=$HOME/lib/
if ! [[ -d $PATH_TO_ALTINSTALL ]]; then
    mkdir $PATH_TO_ALTINSTALL
fi
PATH_TO_PYTHON=$PATH_TO_ALTINSTALL'/bin/python'$PYTHON_VERSION_2DIGITS
if [ ! -f $PATH_TO_PYTHON ] || [ $SHALL_REBUILD -ne 0 ]; then
    echo 'Building python in directory ./Python-'$PYTHON_VERSION
    cd './Python-'$PYTHON_VERSION
    pwd
	echo 'Using prefix:'$PATH_TO_ALTINSTALL
	ls
	
	# To compile with zlib support: following amazing asanadi: 
	# http://stackoverflow.com/questions/12344970/building-python-from-source-with-zlib-support
	find . -type f -samefile 'Modules/Setup.dist' -exec sed -i 's/^[#]zlib/zlib/' {} \;
	cd Modules/zlib
	echo 'Building zlib ...'
	./configure --prefix=$PATH_TO_ALTINSTALL
	make
	make install
	echo '*done*'
	
    cd ../..
	./configure --prefix=$PATH_TO_ALTINSTALL
	#make
	make altinstall
	#echo '*done*'
    #echo '-----------------'
	
    echo 'Using python altinstall binary '$PATH_TO_PYTHON' for the following library builds.'
	
fi

echo $PATH_TO_PYTHON

# To allow to install missing packages easily using 'pip'.
VIRTUALENV='virtualenv-1.9.1'
ARCHIVE=$VIRTUALENV'.tar.gz'
if [[ -f $ARCHIVE ]] && [[ $SHALL_REDOWNLOAD -ne 0 ]]; then
    echo 'Downloading virtualenv ...'
    wget http://pypi.python.org/packages/source/v/virtualenv/$ARCHIVE
    echo '*done*'
fi
if ! [[ -d $VIRTUALENV ]]; then
    echo 'Unpacking ...'
    tar zxvf $ARCHIVE
    echo '*done*'
fi

cd $VIRTUALENV 
echo 'Setting up virtualenv ...'
$PATH_TO_PYTHON setup.py install
echo '*done*'

PATH_TO_CUSTOM_VIRTUALENV=$HOME'/virtualpythonenvironment_python'$PYTHON_VERSION_2DIGITS
if [[ ! -d $PATH_TO_CUSTOM_VIRTUALENV ]]; then
    mkdir $PATH_TO_CUSTOM_VIRTUALENV
	#rm $PATH_TO_CUSTOM_VIRTUALENV -r
fi

echo 'Creating virtualenv in '$PATH_TO_CUSTOM_VIRTUALENV' ...'
$PATH_TO_ALTINSTALL'/bin/virtualenv' $PATH_TO_CUSTOM_VIRTUALENV --python $PATH_TO_PYTHON
echo 'Activating virtualenv (deactive after use via "source '$PATH_TO_CUSTOM_VIRTUALENV'/deactivate") ...'
source $PATH_TO_CUSTOM_VIRTUALENV/activate


# If it's not complaining of missing packages in the altinstall lib/<pythonversion>/site-packages/, then install missing packages. 
#~/shell__kx/kx install pip
#pip install 


# Don't forget to deactivate the virtual environment after use:
#source $PATH_TO_CUSTOM_VIRTUALENV/deactivate
