
#!/bin/sh

set -e
set -o pipefail

Scripts/run_ios14_tests.sh || ios14_error=true
Scripts/run_ios13_tests.sh || ios13_error=true
Scripts/run_ios12_tests.sh || ios12_error=true
Scripts/run_ios11_tests.sh || ios11_error=true

if [ $ios14_error ]; then
	error=true
	echo "iOS 14 Tests Failed."
fi

if [ $ios13_error ]; then
	error=true
	echo "iOS 13 Tests Failed."
fi

if [ $ios12_error ]; then
	error=true
	echo "iOS 12 Tests Failed."
fi

if [ $ios11_error ]; then
	error=true
	echo "iOS 11 Tests Failed."
fi

if [ ! $error ]; then
	echo "All Tests Passed."
    exit -1
fi