#!/bin/sh
#
# Config
# ------
# hooks.restrictfilesize
#   This boolean sets whether file size will be restricted in the
#   repository. By default it won’t be.
# hooks.maxfilesize
#   This integer sets the maximum file size (in bytes) allowed to be
#   added into the repository. By default 10485760 (= 10 MiB)
#

# --- Command line
refname="$1"
oldrev="$2"
newrev="$3"

# --- Safety check
if [ -z "$GIT_DIR" ]; then
	echo "Don't run this script from the command line." >&2
	echo " (if you want, you could supply GIT_DIR then run" >&2
	echo "  $0 <ref> <oldrev> <newrev>)" >&2
	exit 1
fi

if [ -z "$refname" -o -z "$oldrev" -o -z "$newrev" ]; then
	echo "usage: $0 <ref> <oldrev> <newrev>" >&2
	exit 1
fi

# --- Config
restrictfilesize=$(git config --bool hooks.restrictfilesize)
[ "$restrictfilesize" != "true" ] && exit 0
maxfilesize=$(git config --int hooks.maxfilesize)
[ -z "$maxfilesize" ] && maxfilesize=10485760

# --- Check
zero="0000000000000000000000000000000000000000"
if [ "$newrev" = "$zero" ]; then
	# delete reference
	exit 0
fi

if [ "$oldrev" = "$zero" ]; then
	# create reference -> compare to all existing references
	oldrev=$(git for-each-ref --format='%(refname)')
fi

for rev in $(git rev-list --reverse $newrev --not $oldrev); do
	biggest_file=$(git ls-tree --full-tree -r -l $rev | sort -k 4 -n -r | head -1 | awk '{print $5,$4}')
	filename=$(echo $biggest_file | cut -d ' ' -f1)
	filesize=$(echo $biggest_file | cut -d ' ' -f2)

	if [ $filesize -gt $maxfilesize ]; then
		echo "*** Creating files bigger than $maxfilesize bytes is not allowed in this repository" >&2
		echo "*** The commit $rev you're trying to push creates file '$filename' of size $filesize bytes" >&2
		exit 1
	fi
done

# --- Finished
exit 0
