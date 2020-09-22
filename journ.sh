#!/bin/bash

JOURNAL_DIR="$HOME/.journeh"
DATE="$(date -u +%F)"

function new_entry() {
	touch $1
	vim "+normal G$" +startinsert $1
	git add .
}

function daily() {
	new_entry "$JOURNAL_DIR/$DATE.md"
	
        git commit -m "update daily entry $DATE"
}

function weekly() {
	FIRST_DAY=$(date -u -d "sunday - $(( $(date -u +%s) - $(date -u -d "$DATE" +%s) ) / 86400 )) days" +%F)
	WEEK_NAME=$(date -u -d "$file_date" +%Y-%V)
	printf "# %s\n" $WEEK_NAME > $JOURNAL_DIR/.$WEEK_NAME.md
	
	for $(( i=0; i<7; i += 1 ));
	do
		file_date=$(date -u -d "$FIRST_DAY + $i" days)
		printf "\n## %s\n" $(date -u -d "$file_date" +%A) >> $JOURNAL_DIR/.$WEEK_NAME.md
		if [ -f $file_date ];
		then
			cat $JOURNAL_DIR/$file_date.md >> $JOURNAL_DIR/.$WEEK_NAME.md
		fi
	done

	echo "## Weekly Summary" > $JOURNAL_DIR/.$WEEK_NAME.md 
	awk '/## Weekly Summary/,EOF' | tail -n +2 >> $JOURNAL_DIR/.$WEEK_NAME.md
	mv -f $JOURNAL_DIR/.$WEEK_NAME.md $JOURNAL_DIR/$WEEK_NAME.md
	
	new_entry "$JOURNAL_DIR/$WEEK_NAME.md"

        git commit -m "update weekly entry for week $WEEK_NAME starting on $FIRST_DAY"
}

if [ "_$1" != "_init" ] && [ ! -d ${JOURNAL_DIR} ];
then
	echo "Your journal directory has not been initialized, please run 'init <repo url>' first"
fi

case "_$1" in
	_init)
		git clone $2 ${JOURNAL_DIR}
		;;
	_day)
		[ "_${*:2}" != "_" ] && DATE=$(date -u -d "${*:2}" +%F)
		daily $DATE
		git push
		;;
	_week)
		[ "_${*:2}" != "_" ] && DATE=$(date -u -d "${*:2}" +%F)
		weekly $DATE
		git push
		;;
	_help|_)
		echo "
		Usage:
			new
			help
			"
		;;
esac

	

