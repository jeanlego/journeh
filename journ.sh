#!/bin/bash

# are set internally but exposed
DATE=""
ENTRY_NAME=""
FROM=""
TO=""

# can be overriden by conf later
THIS_DIR=$(dirname $(readlink -f $0))
JOURNAL_DIR="$HOME/.journeh"
CONTEXT_BEFORE=1
CONTEXT_AFTER=1
# CONTEXT=1
AT_TOP=1
OLDEST_FIRST=0
# day 1 since, day 0 would break some of the logic
EPOCH=$(date -d "@1" +%F)

function init_file() {
    if [ ! -f "$1" ];
    then
        template="$JOURNAL_DIR/.template.md"
        [ ! -f template ] && template="${PWD}/template.md"
        [ ! -f template ] && template="${THIS_DIR}/template.md"

        for VARNAME in $(grep -P -o -e '\$[\{]?(\w+)*[\}]?' "$template" | sort -u); do     
            VARNAME2=$(echo "$VARNAME"| sed -e 's|^\${||g' -e 's|}$||g' -e 's|^\$[^(]||g' );
            VAR_VALUE2=${!VARNAME2};

            if [ "_" != "_$VAR_VALUE2" ]; then
                sed  "s|$VARNAME|$VAR_VALUE2|g" "$template" >> "$1"; 
            fi      
        done
    fi
}

function write_back() {
    filename=""
    while IFS="" read -r lines || [ -n "$lines" ]
    do
        case "$lines" in
            '<!--BEGIN-'*'-->')
                lines=${lines/<\!--BEGIN-/} 
                lines=${lines/-->/} 
                filename="$JOURNAL_DIR/$lines.md"
                rm "$filename" &> /dev/null
            ;;
            *)
                echo "$lines" >> "$filename"
            ;;
        esac
    done < "$1"
}

function load_entry() {
    local _starts_at
    {
        [ -f "$JOURNAL_DIR/$1.md" ] && [ -n "$(tail -c1 "$JOURNAL_DIR/$1.md")" ] &&\
            echo "";
        echo "<!--BEGIN-$1-->";
    } >> "$2";  
    _starts_at="$(wc -l "$2" | awk '{print $1}')"
    {
            [ -f "$JOURNAL_DIR/$1.md" ] &&\
            cat "$JOURNAL_DIR/$1.md";
    } >> "$2"; 
    echo "$_starts_at"
}

function split() {
    read -r input
    delimiter="$*"
    input="$input$delimiter" 
    while [[ $input ]]; do
        echo "${input%%"$delimiter"*}"
        input=${input#*"$delimiter"}
    done
}

function parse_args() {
    FROM="$(date +%F)"
    TO="${FROM}"

    case "_$1" in
        _)
            ;;
        _todo)
	    # we had things since the beginning of time... let it show
	    DATE="${EPOCH}"
	    FROM="${EPOCH}"
	    TO="${EPOCH}"
	    ;;
        _day)
            [ "_${*:2}" != "_" ] && DATE=$(date -d "${*:2}" +%F)
            FROM=${DATE}
            TO="${FROM}"
            ;;
        _week)
            [ "_${*:2}" != "_" ] && DATE=$(date -d "${*:2}" +%F)
            FROM=$(date -d "$DATE - $(date -d "$DATE" +%u) days" +%F)
            TO=$(date -d "$FROM + 6 days" +%F)
            ;;
        _month)
            [ "_${*:2}" != "_" ] && DATE=$(date -d "${*:2}" +%F)
            local _days_in_month
            _days_in_month=$(cal "$DATE" | awk 'NF {DAYS = $NF}; END {print DAYS}')
            FROM=$(date -d "$DATE" +"%Y-%m-01")
            TO=$(date -d "$DATE" +"%Y-%m-$_days_in_month")
            ;;
        _quarter)
            [ "_${*:2}" != "_" ] && DATE=$(date -d "${*:2}" +%F)
            local _quarter_len
            local _last_day_of_quarter
            local _year
            _quarter_len=91
            _last_day_of_quarter=$(( _quarter_len  * $(date -d "$DATE" +%q) ))
            _year=$(date -d "$DATE" +"%Y")
            TO=$(date -d "$_year-01-01 + $_last_day_of_quarter days" +"%F")
            FROM=$(date -d "$TO - $_quarter_len days" +%F)
            ;;
        _year)
            [ "_${*:2}" != "_" ] && DATE=$(date -d "${*:2}" +%F)
            local _year
            _year=$(date -d "$DATE" +"%Y")
            FROM=$(date -d "$_year-01-01" +"%F")
            TO=$(date -d "$_year-12-31" +"%F")
            ;;

        _*)
            case "_$*" in
                _*' to '*)
                    mapfile -t values <<< "$(echo "$*" | split " to ")"
                    FROM="$(date -d"${values[0]}" +%F)"
                    TO="$(date -d"${values[1]}" +%F)"

                    ;;
                _*' from '*)
                    mapfile -t values <<< "$(echo "$*" | split " from ")"
                    FROM="$(date -d"${values[0]}" +%F)"
                    TO="$(date -d"$DATE ${values[1]}" +%F)"
                    ;;
                _*)
                    FROM="$(date -d"$*" +%F)"
                    TO="$FROM"
                    ;;
            esac
            ;;
    esac
}

function journeh() {

    git ls-remote &> /dev/null
    REMOTE=$?

    # convert to second
    FROM=$(date -d"${FROM}" +%s)
    TO=$(date -d"${TO}" +%s)
    if (( FROM  > TO ));
    then
        local _tmp_date
        _tmp_date=$FROM
        FROM=$TO
        TO=$_tmp_date                    
    fi
    local _diff_days
    _diff_days=$(( ( TO - FROM ) / 86400 ))
    # convert back
    FROM=$(date -d"@$FROM" +%F)
    TO=$(date -d"@$TO" +%F)

    local _context_before_end
    local _context_after_start
    _context_before_end=1
    _context_after_start=1
    if [ "_${_diff_days}" == "_0" ];
    then
	DATE="${FROM}"
        ENTRY_NAME="${DATE}"
	
    else
        # override context
        if [[ "_$AT_TOP"  == "_$OLDEST_FIRST" ]]
        then
            CONTEXT_BEFORE="${_diff_days}"
            _context_before_end=0
            DATE="${TO}"
            CONTEXT_AFTER=0
        else
            CONTEXT_BEFORE=0
            DATE="${FROM}"
            CONTEXT_AFTER="${_diff_days}"
            _context_after_start=0
        fi

        ENTRY_NAME="${FROM}_to_${TO}"
    fi

    local _tmp_file
    _tmp_file=$(mktemp --suffix=.md)
    local _line_number
    _line_number=0

    # sync with remote
    [[ -z $REMOTE ]] && git pull
    
    if [ "$OLDEST_FIRST" == "0" ];
    then
        # import all the previous context
        for (( i = CONTEXT_BEFORE; i >= _context_before_end; i -= 1 ));
        do
            load_entry "$(date -d "$DATE - $i days" +%F)" "$_tmp_file" &> /dev/null
        done
    else
        # import all the previous context
        for (( i = CONTEXT_AFTER; i >= _context_after_start; i -= 1 ));
        do
            load_entry "$(date -d "$DATE + $i days" +%F)" "$_tmp_file"  &> /dev/null
        done
    fi

    init_file "$JOURNAL_DIR/$ENTRY_NAME.md"
    _line_number="$(load_entry "$ENTRY_NAME" "$_tmp_file")"

    if [ "$OLDEST_FIRST" == "0" ];
    then 
        # import all the previous context
        for (( i = _context_after_start; i <= CONTEXT_AFTER; i += 1 ));
        do
            load_entry "$(date -d "$DATE + $i days" +%F)" "$_tmp_file"  &> /dev/null
        done
    else
        # import all the previous context
        for (( i = _context_before_end; i <= CONTEXT_BEFORE; i += 1 ));
        do
            load_entry "$(date -d "$DATE - $i days" +%F)" "$_tmp_file"  &> /dev/null
        done
    fi

    # open for changes and writeback on success
    vim +"$_line_number" "$_tmp_file" && write_back "$_tmp_file"

    # push sync with remote
    git add . &> /dev/null
    git commit -m "update $ENTRY_NAME" &> /dev/null
    [[ -z $REMOTE ]] && git push

}


if [ -d "$JOURNAL_DIR" ]
then
    cd "$JOURNAL_DIR"
elif [ "_$1" != "_init" ]
then
    echo "Your journal directory has not been initialized, please run 'init <repo url>' first"
fi

case "_$1" in
    _init)
	mkdir -p "$JOURNAL_DIR"
	pushd "$JOURNAL_DIR"
	[ ! -d .git ] && git init
	git ls-remote &> /dev/null && git remote remove origin
	[ "_$2" != "_" ] && git remote add origin "$2"
        ;;
    _help)
        echo "
    Usage:
        init <git url>                               this will init the repo for remote backup
	todo                                         create/update a rolling todo list
        day  [date -d arguments]                     create a daily journal entry
        week [date -d arguments]                     create a weekly-end journal entry    
        month [date -d arguments]                    create a month-end journal entry
        quarter [date -d arguments]                  create a quarter-end journal entry
        year [date -d arguments]                     create a year-end journal entry
        [date -d arguments] to [date -d arguments]   create a ranged journal entry
        [date -d arguments] from [date -d arguments] create a relative from ranged journal entry
        [date -d arguments]                          create a daily journal entry for date
        <blank>                                      create a daily journal entry for today                
        help                                         this
            "
        ;;
    *)
        parse_args "${@}"
        journeh
        ;;
esac

