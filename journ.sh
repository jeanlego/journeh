#!/bin/bash

JOURNAL_DIR="$HOME/.journeh"
DATE="$(date -u +%F)"

function new_entry() {
	printf "%s\n\n" "${*:2}" > $JOURNAL_DIR/.$1.md
        awk "/$2/,EOF" $JOURNAL_DIR/$1.md | tail -n +2 >> $JOURNAL_DIR/.$1.md
	
	vim "+normal G$" +startinsert $JOURNAL_DIR/.$1.md
	if ! wdiff -1 -2 -3 -n \
  	 -w $'\033[30;31m' -x $'\033[0m' \
  	 -y $'\033[30;32m' -z $'\033[0m' \
	 $JOURNAL_DIR/$1.md $JOURNAL_DIR/.$1.md &> /dev/null;
	then
		mv -f $JOURNAL_DIR/.$1.md $JOURNAL_DIR/$1.md
		git add .
		git commit -m "update $2"
		git push
	fi
}

function daily() {
	new_entry "$DATE" "# Entry $DATE"
}

function weekly() {
	FIRST_DAY=$(date -u -d "sunday - $(( $(date -u +%s) - $(date -u -d "$DATE" +%s) ) / 86400 )) days" +%F)
	WEEK_NAME=$(date -u -d "$file_date" +%Y-%V)
	printf "# %s\n" "$WEEK_NAME" > $JOURNAL_DIR/.$WEEK_NAME.md
	
	for $(( i=0; i<7; i += 1 ));
	do
		file_date=$(date -u -d "$FIRST_DAY + $i" days)
		printf "\n## %s\n" $(date -u -d "$file_date" +%A) >> $JOURNAL_DIR/.$WEEK_NAME.md
		if [ -f $file_date ];
		then
			# drop the header
		        awk "/# /,EOF" $JOURNAL_DIR/$file_date.md | tail -n +2 >> $JOURNAL_DIR/.$WEEK_NAME.md
		fi
	done
	
	new_entry "$WEEK_NAME" "## Weekly Summary"
}

if [ "_$1" != "_init" ] && [ ! -d ${JOURNAL_DIR} ];
then
	echo "Your journal directory has not been initialized, please run 'init <repo url>' first"
else
	cd ${JOURNAL_DIR}
	# clean old temp files
	rm ./.*.md &> /dev/null
fi

case "_$1" in
	_init)
		git clone $2 ${JOURNAL_DIR}
		;;
	_day)
		[ "_${*:2}" != "_" ] && DATE=$(date -u -d "${*:2}" +%F)
		daily $DATE
		;;
	_week)
		[ "_${*:2}" != "_" ] && DATE=$(date -u -d "${*:2}" +%F)
		weekly $DATE
		;;
	_help|_)
		echo "
		Usage:
			new
			help
			"
		;;
esac

	

