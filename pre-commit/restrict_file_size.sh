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

# --- Config
restrictfilesize=$(git config --bool hooks.restrictfilesize)
[ "$restrictfilesize" != "true" ] && exit 0
maxfilesize=$(git config --int hooks.maxfilesize)
[ -z "$maxfilesize" ] && maxfilesize=10485760

# --- Check
if git rev-parse --verify HEAD >/dev/null 2>&1
then
	against=HEAD
else
	# Initial commit: diff against an empty tree object
	against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

IFS='
'
for filename in $(git diff-index --cached --name-only $against); do
	filesize=$(git show :"$filename" | wc --bytes)

	if [ $filesize -gt $maxfilesize ]; then
		echo "*** Creating files bigger than $maxfilesize bytes is not allowed in this repository" >&2
		echo "*** The commit you're trying to do creates file '$filename' of size $filesize bytes" >&2
		exit 1
	fi
done

# --- Finished
exit 0
