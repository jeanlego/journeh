#!/bin/bash

JOURNAL_DIR="$HOME/.journeh"
DATE="$(date +%F)"

function init_file() {
    if [ ! -f "$JOURNAL_DIR/$1.md" ];
    then
        printf "# %s\n\n" "$1" >> "$JOURNAL_DIR/$1.md"
    fi
}

function daily() {
    init_file "$DATE"
    vim "+normal G$" "$JOURNAL_DIR/$DATE.md"
}

function periodic() {
    FIRST_DAY=$(date -d "$DATE - $(date -d "$DATE - 1 days" +"$2") days" +%F)
    PERIOD_NAME=$(date -d "$DATE" +"%Y-$1$3")
    echo "period -- $4"
    # import all the files into one
    for (( i=0; i<=$4; i += 1 ));
    do
        filename="$(date -d "$FIRST_DAY + $i days" +%F)"
        if (( i == $4 ));
        then
            filename=$PERIOD_NAME
        fi

        init_file "$filename"
        {
            [ -n "$(tail -c1 "$JOURNAL_DIR/$filename.md")" ] && printf "\n"
            printf "<!--BEGIN-%s-->\n" "$filename";
            cat "$JOURNAL_DIR/$filename.md";
        } >> "$JOURNAL_DIR/.$PERIOD_NAME.md"
    done
    
    # open for changes
    vim "+normal G$" "$JOURNAL_DIR/.$PERIOD_NAME.md"

    filename=""
    while IFS="" read -r lines || [ -n "$lines" ]
    do
        case "$lines" in
            '<!--BEGIN-'*'-->')
                lines=${lines/<\!--BEGIN-/} 
                lines=${lines/-->/} 
                filename="$JOURNAL_DIR/$lines.md"
                rm "$filename"
            ;;
            *)
                echo "$lines" >> "$filename"
            ;;
        esac
    done < "$JOURNAL_DIR/.$PERIOD_NAME.md"
}

if [ "_$1" != "_init" ] && [ ! -d "$JOURNAL_DIR" ];
then
    echo "Your journal directory has not been initialized, please run 'init <repo url>' first"
else
    cd "$JOURNAL_DIR" || exit
    # clean old temp files
    rm ./.*.md &> /dev/null
fi

case "_$1" in
    _init)
        git clone "$2" "$JOURNAL_DIR"
        exit
        ;;
    _day)
        [ "_${*:2}" != "_" ] && DATE=$(date -d "${*:2}" +%F)
        daily
        ;;
    _week)
        [ "_${*:2}" != "_" ] && DATE=$(date -d "${*:2}" +%F)
        periodic "W" "%u" "%W" 7
        ;;
    _month)
        days_in_month=$(cal "$DATE" | awk 'NF {DAYS = $NF}; END {print DAYS}')
        periodic "M" "%d" "%m" "$days_in_month"
        ;;
    _help|_)
        echo "
        Usage:
            new
            help
            "
        exit 0
        ;;
esac

git add .
git commit -m "update $1 of $DATE"
git push


    

