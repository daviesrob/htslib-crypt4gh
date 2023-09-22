#!/bin/sh

pass_count=0
fail_count=0

show_pass_or_fail () {
    local res="$1"
    local name="$2"

    if [ $res -ne 0 ]; then
        echo "Failed: $name" 1>&2
        fail_count=$(($fail_count + 1))
    else
        echo "Passed: $name" 1>&2
        pass_count=$(($pass_count + 1))
    fi
}

# Find htsfile

echo -n "Looking for htsfile (HTSDIR=$HTSDIR) ... " 1>&2

HTSFILE='no'
if [ -x $HTSDIR/bin/htsfile ] ; then
    HTSFILE=$HTSDIR/bin/htsfile
else if [ -x $HTSDIR/htsfile ] ; then
	 HTSFILE=$HTSDIR/htsfile
     fi
fi

if [ $HTSFILE = "no" ] ; then
    echo "Couldn't find htsfile" 1>&2
    exit 1
else
    echo "$HTSFILE" 1>&2
fi

# Set path to find plugin

HTS_PATH=plugin
export HTS_PATH

# Round trip test

"$HTSFILE" -C test/ce#1.sam crypt4gh:test/ce#1.tmp.encrypted.sam && \
"$HTSFILE" -C crypt4gh:test/ce#1.tmp.encrypted.sam test/ce#1.tmp.sam && \
cmp test/ce#1.sam test/ce#1.tmp.sam
show_pass_or_fail $? 'Round trip test'

# Test auto-detection
"$HTSFILE" -c test/ce#1.tmp.encrypted.sam > test/ce#1.tmp.2.sam && \
cmp test/ce#1.sam test/ce#1.tmp.2.sam
show_pass_or_fail $? 'Auto-detection test'

# Test encrypted htsget
# Normal htsget input
"$HTSFILE" -c test/ce#1.htsget > test/ce#1.tmp.3.sam && \
cmp test/ce#1.sam test/ce#1.tmp.3.sam
show_pass_or_fail $? 'htsget test'

# Encrypted htsget payload
"$HTSFILE" -c test/ce#1_encrypted.htsget > test/ce#1.tmp.4.sam && \
cmp test/ce#1.sam test/ce#1.tmp.4.sam
show_pass_or_fail $? 'htsget encrypted payload test'

# Encrypted htsget response
"$HTSFILE" -C test/ce#1.htsget crypt4gh:test/ce#1.tmp.encrypted.htsget && \
"$HTSFILE" -c test/ce#1.tmp.encrypted.htsget > test/ce#1.tmp.5.sam && \
cmp test/ce#1.sam test/ce#1.tmp.5.sam
show_pass_or_fail $? 'htsget encrypted response test'

# Encrypted htsget payload and response
"$HTSFILE" -C test/ce#1_encrypted.htsget crypt4gh:test/ce#1.tmp.2encrypted.htsget && \
"$HTSFILE" -c test/ce#1.tmp.2encrypted.htsget > test/ce#1.tmp.6.sam && \
cmp test/ce#1.sam test/ce#1.tmp.6.sam
show_pass_or_fail $? 'htsget encrypted payload and response test'

if [ $fail_count -eq 0 ] ; then
    echo "Passed"
    exit 0
else
    echo "Failed"
    exit 1
fi
