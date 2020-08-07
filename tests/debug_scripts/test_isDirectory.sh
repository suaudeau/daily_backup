currentDir=$(pwd)
cd ../../

#Include global functions
. "$(dirname "${0}")/lib/inc_lib.sh"
. "$(dirname "${0}")/lib/inc_lib_backup.sh"

pathToTest=${USER}@127.0.0.1:${currentDir}/

echo "Test of : isDirectory $pathToTest"

if isDirectory $pathToTest ; then
    echo "Dir présent!"
else
	echo "error"
fi
cd $currentDir
