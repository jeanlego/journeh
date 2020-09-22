#!/bin/bash

JOURNAL_DIR="~/.journeh"
DATE="$(date -u +%F)"

# init essential directories
[ ! -d $JOURNAL_DIR ] && mkdir $JOURNAL_DIR

function new_entry() {
	touch $1
	vim "+normal G$" +startinsert $1
	git add .
	git commit -m "update file $DATE"
}

function daily() {
	[ "_${*:2}" != "_" ] && DATE=$(date -u -d "${*:2}" +%F)
	
	new_entry "$JOURNAL_DIR/$DATE.md"
	git add .
        git commit -m "update daily entry $DATE"
	git push
}

function weekly() {
	[ "_${*:2}" != "_" ] && DATE=$(date -u -d "${*:2}" +%F)       
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

	git add .
        git commit -m "update weekly entry for week $WEEK_NAME starting on $FIRST_DAY"
	git push
}

case "_$1" in
	_day)
		new_entry $DATE "${2//[^0-9\+\-]/}"
		;;
	_week)
		new_entry $DATE "${2//[^0-9\+\-]/}"
		;;
	_help|_)
		echo "
		Usage:
			new
			help
			"
		;;
esac

	

