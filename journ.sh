#!/bin/bash

THIS_DIR="$(dirname "$(readlink -f "$0")")"
JOURNAL_DIR="$HOME/.journ"
ENTRY_DIR="$JOURNAL_DIR/entries"

DATE="$(date -u +%F)"

YEAR="$(date +%Y)"
WEEK="$(date +%V)"
DOW="$(date +%u)"
FILE_NAME="$YEAR-$WEEK-$DOW.md"

JOURN_DAY="$ENTRY_DIR/$YEAR-$WEEK-$DOW.md"
JOURN_WEEK="$ENTRY_DIR/$YEAR-$WEEK.md"

function new_entry() {
	touch $1
	vim "+normal G$" +startinsert $1
	git add .
	git commit -m "update file $DATE"
}

function daily() {
	case _$2 in
		_);;
		-*)
			DATE=$(date -u -d "$DATE - ${2/[^0-9]/} days" +%F)
			;;
		_*-*-*)
			DATE=$(date -u -d "$DATE" +%F)
			;;
	esac
	new_entry "$ENTRY_DIR/$DATE.md"
	git add .
        git commit -m "update daily entry $DATE"
}

function weekly() {
        case _$2 in
                _);;
                -*)
                        DATE=$(date -u -d "$DATE - ${2/[^0-9]/} weeks" +%F)
                        ;;
                _*-*-*)
                        DATE=$(date -u -d "$DATE" +%F)
                        ;;
        esac

	FIRST_DAY=$(date -u -d "sunday - $(( ( $(date -u +%s) - $(date -u -d "$DATE" +%s) ) / 86400 )) days" +%F)
	
	WEEK_NAME=$(date -u -d "$file_date" +%Y-%V)
	printf "# %s\n" $WEEK_NAME > $ENTRY_DIR/.$WEEK_NAME.md
	
	for $(( i=0; i<7; i += 1 ));
	do
		file_date=$(date -u -d "$FIRST_DAY + $i" days)
		printf "\n## %s\n" $(date -u -d "$file_date" +%A) >> $ENTRY_DIR/.$WEEK_NAME.md
		if [ -f $file_date ];
		then
			cat $ENTRY_DIR/$file_date.md >> $ENTRY_DIR/.$WEEK_NAME.md
		fi
	done

	echo "## Weekly Summary" > $ENTRY_DIR/.$WEEK_NAME.md 
	awk '/## Weekly Summary/,EOF' | tail -n +2 >> $ENTRY_DIR/.$WEEK_NAME.md
	mv -f $ENTRY_DIR/.$WEEK_NAME.md $ENTRY_DIR/$WEEK_NAME.md
	new_entry "$ENTRY_DIR/$WEEK_NAME.md"

	git add .
        git commit -m "update weekly entry for week $WEEK_NAME starting on $FIRST_DAY"
}

case "_$1" in
	_day)
		new_entry $JOURN_DAY "${2//[^0-9\+\-]/}"
		;;
	_week)
		new_entry $JOURN_WEEK "${2//[^0-9\+\-]/}"
		;;
	_help|_)
		echo "
		Usage:
			new
			help
			"
		;;
esac

	

