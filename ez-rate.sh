#!/bin/bash

# ez-rate.sh
# uses geeqie to show two images
# displays vote buttons
# sums up votes

FOLDER=$1
[[ ! -d $FOLDER ]] && echo "$FOLDER is not a folder" && exit 1
[[ ! -w $FOLDER ]] && echo "$FOLDER is not writeable" && exit 2

GEEQIE=/usr/bin/geeqie
ZENITY=/usr/bin/zenity
EXIFTOOL=/usr/bin/vendor_perl/exiftool

# mandatory programs
for NEEDED in $GEEQIE $ZENITY $EXIFTOOL
do
    command -v $NEEDED >/dev/null 2>&1
    if [[ $? -ne 0 ]]
    then
        echo "$NEEDED not installed"
        exit 4
    fi
done

function handler() {
    pkill geeqie
	exit 0
}
trap handler SIGINT

while true
do
	# https://stackoverflow.com/a/16758439
	# https://stackoverflow.com/a/414316
	# https://stackoverflow.com/a/44112055
	{ read img1; read img2; } <<< $(find "$FOLDER" -type f -name '*' -exec file {} \; | grep -o -P '^.+: \w+ image' | cut -d: -f1 | sort -R | tail -n2)
	echo -e "$img1\n $img2"

	[[ ! -w "$img1" ]] || [[ ! -w "$img2" ]] && echo "$img1 or $img2 are not writeable!" && exit 4

	$GEEQIE -t --geometry=960x540+0+0 $img1 > /dev/null 2>&1 &
	$GEEQIE -t --geometry=960x540+960+0 $img2 > /dev/null 2>&1 &

	# --question returns 0 for ok-label and 1 for cancel-label
	answer=$($ZENITY --question \
	--title="" \
	--text "Choose A or B" \
	--ok-label="B" \
	--cancel-label="A")

	if [[ $? -eq 1 ]]
	then
		img="$img1"
	else
		img="$img2"
	fi

	oldrating=$($EXIFTOOL -s3 -UserComment "$img")
	echo "oldrating: $oldrating"
	[[ $oldrating == "" ]] || [[ -z $oldrating ]] || [[ ! $oldrating =~ "^[0-9]+$" ]] && oldrating=0
	newrating=$(( oldrating + 1 ))
	echo "newrating: $newrating"
	$EXIFTOOL -UserComment=$newrating -overwrite_original "$img"
	pkill geeqie
	sleep 1
done


