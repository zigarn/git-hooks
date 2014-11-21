#!/bin/sh
#
# Config
# ------
# hooks.forcepullrebase
#   This boolean sets whether not rebased pulls will be allowed into the
#   repository.  By default this is allowed.
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
forcepullrebase=$(git config --bool hooks.forcepullrebase)
[ "$forcepullrebase" != "true" ] && exit 0

# --- Check
zero="0000000000000000000000000000000000000000"
if [ "$newrev" = "$zero" -o "$oldrev" = "$zero" ]; then
	# delete reference
	exit 0
fi

if ! git rev-list --first-parent $newrev | grep $oldrev > /dev/null 2>&1
then
	refname=$(git rev-parse --abbrev-ref $refname)
	echo "*** Pushing not rebased pulls is not allowed in this repository" >&2
	echo "*** Please run 'git rebase $refname@{u} $refname'" >&2
	exit 1
fi

# --- Finished
exit 0
