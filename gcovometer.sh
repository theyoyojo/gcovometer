#!/bin/sh

list_files=
kernel_file=
reset_cov=
make_report=
SRCDIR="/builddir/build/BUILD/kernel-6.12.0-74.gcov.ns.selftest.el10/linux-6.12.0-74.gcov.el10_0.aarch64"
COVDIR="/sys/kernel/debug/gcov/${SRCDIR}"
script_dir=$(realpath $(dirname $0))
TESTS=

while getopts "l:r:t:mc" OPTION; do
	case $OPTION in
		l)
			echo "get list for kernel file $OPTARG"
			kernel_file=$OPTARG
			list_files=y
			;;
		r)
			echo "will reset all gcov dependencies of $OPTARG"
			reset_gcov=y
			kernel_file=$OPTARG
			;;
		t)
			echo "will run test $OPTARG"
			TESTS="$TESTS $OPTARG"
			;;
		m)
			echo "will create covreport"
			make_report=y
			;;
		c)
			echo "will clean up and exit"
			rm -f *.gcov *covreport *covlist
			exit 0
			;;
	esac
done
shift $((OPTIND - 1))

path_to_hashes() { echo ${1//\//#} ; } ;

mk_covlist_path() { echo $script_dir/$(path_to_hashes $1).covlist ; } ;

if [ ! -z "$reset_gcov" ] && [ ! -f $(mk_covlist_path $kernel_file) ]; then
	echo "list not present, creating"
	list_files=y
fi

if [ ! -z "$list_files" ]; then

	dir=$(dirname $kernel_file)

	pushd . >/dev/null
	cd $SRCDIR
	gcov -p -H -o $COVDIR/$dir $kernel_file >/dev/null

	for outfile in $(ls | grep "^.*\.gcov$"); do
		covfile=${outfile//#/\/}
		file=${covfile//.gcov/}
		echo $file
	done > $(mk_covlist_path $kernel_file)
	rm -f *.gcov
	popd >/dev/null

fi


if [ ! -z "$reset_gcov" ]; then
	for file in $(grep "^.*\.c" $(mk_covlist_path $kernel_file)); do
		echo "do reset for $file"
		echo "" > $COVDIR/${file::-2}.gcda
	done
fi

if [ ! -z "$TESTS" ]; then
	for t in $TESTS; do
		echo "run $t"
		$t
	done

fi

if [ ! -z "$make_report" ]; then

	dir=$(dirname $kernel_file)

	pushd . >/dev/null
	cd $SRCDIR
	gcov -p -H -o $COVDIR/$dir $kernel_file > $script_dir/$(path_to_hashes $kernel_file).covreport

	cp *.gcov $script_dir
	popd >/dev/null

fi
