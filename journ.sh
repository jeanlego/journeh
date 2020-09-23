#!/bin/bash

THIS_DIR=$(dirname $(readlink -f $0))
JOURNAL_DIR="$HOME/.journeh"
DATE="$(date +%F)"

function init_file() {
    if [ ! -f "$1" ];
    then
        template="$JOURNAL_DIR/.template.md"
        [ ! -f template ] && template="${PWD}/template.md"
        [ ! -f template ] && template="${THIS_DIR}/template.md"

        for VARNAME in $(grep -P -o -e '\$[\{]?(\w+)*[\}]?' "$template" | sort -u); do     
            VARNAME2=$(echo "$VARNAME"| sed -e 's|^\${||g' -e 's|}$||g' -e 's|^\$||g' );
            VAR_VALUE2=${!VARNAME2};

            if [ "_" != "_$VAR_VALUE2" ]; then
                sed  "s|$VARNAME|$VAR_VALUE2|g" "$template" >> "$1"; 
            fi      
        done
    fi
}

function daily() {
    PERIOD="$DATE"
    init_file "$JOURNAL_DIR/$DATE.md"

    vim "+normal G$" "$JOURNAL_DIR/$DATE.md"
}

function periodic() {
    PERIOD=$(date -d "$DATE" +"%Y$2$3")
    # import all the files into one
    for (( i=0; i<=$4; i += 1 ));
    do
        filename="$(date -d "$1 + $i days" +%F)"
        if (( i == $4 ));
        then
            filename=$PERIOD
            init_file "$JOURNAL_DIR/$PERIOD.md"
        fi

        if [ -f "$JOURNAL_DIR/$filename.md" ];
            then
            {
                [ -n "$(tail -c1 "$JOURNAL_DIR/$filename.md")" ] && printf "\n"
                printf "<!--BEGIN-%s-->\n" "$filename";
                cat "$JOURNAL_DIR/$filename.md";
            } >> "$JOURNAL_DIR/.$PERIOD.md"    
        fi
    done
    
    # open for changes
    vim "+normal G$" "$JOURNAL_DIR/.$PERIOD.md"

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
    done < "$JOURNAL_DIR/.$PERIOD.md"
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
        days_in_week=7
        FIRST_DAY=$(date -d "$DATE - $(date -d "$DATE - 1 days" +%u) days" +%F)
        periodic "$FIRST_DAY" "-W" "%W" $days_in_week
        ;;
    _month)
        [ "_${*:2}" != "_" ] && DATE=$(date -d "${*:2}" +%F)
        days_in_month=$(cal "$DATE" | awk 'NF {DAYS = $NF}; END {print DAYS}')
        FIRST_DAY=$(date -d "$DATE - $(date -d "$DATE - 1 days" +%d) days" +%F)
        periodic "$FIRST_DAY" "-M" "%m" "$days_in_month"
        ;;
    _quarter)
        [ "_${*:2}" != "_" ] && DATE=$(date -d "${*:2}" +%F)
        current_quarter="$(date -d "$DATE" +%q)"
        days_in_quarter=91 # the last two days are throw aways anyways
        FIRST_DAY=$(( days_in_quarter * ( current_quarter - 1 ) ))
        periodic "$FIRST_DAY" "-Q" "%q" "$days_in_quarter"
        ;;
    _year)
        [ "_${*:2}" != "_" ] && DATE=$(date -d "${*:2}" +%F)
        days_in_year=365 # dont bother with the odd year
        periodic "1" "" "" "$days_in_year"
        ;;
    _help|_)
        echo "
        Usage:
            init <git url>                  this will init the repo for remote backup
            day  [date -d arguments]        create a daily journal entry
            week [date -d arguments]        create a weekly-end journal entry    
            month [date -d arguments]       create a month-end journal entry
            quarter [date -d arguments]     create a quarter-end journal entry
            year [date -d arguments]        create a year-end journal entry
            help                            this
            "
        exit 0
        ;;
esac

git add .
git commit -m "update $1 of $DATE"
git push


    

