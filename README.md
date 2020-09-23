# journeh

## What is it

> Do you wish you were better organized and you live in the terminal. 
> Do you wish you could write a daily 'memoir' like all those pro out there just going full ham.
> 
> Look no more son! I got the tool for you, journeh: A french canadian tool, like it's author.
> This is the outcome of taking the canadianism "Eh!" and the french word "Journee"
> it also is (ish) the command you will use most often `journ day`
>
> Journeh, a tool to organize your daily shenanigans, even by quarters for you BA afficionados.


## Usage

journ  
    `init <git url>`                  this will init the repo for remote backup.  
    `day  [date -d arguments]`        create a daily journal entry.  
    `week [date -d arguments]`        create a weekly-end journal entry.  
    `month [date -d arguments]`       create a month-end journal entry.  
    `quarter [date -d arguments]`     create a quarter-end journal entry.  
    `year [date -d arguments]`        create a year-end journal entry.  
    `help`                            this.  

For the date arguments, see the [gnu core util `date` --date input format](https://www.gnu.org/software/coreutils/manual/html_node/Date-input-formats.html#Date-input-formats)

Some (but not limited) quick example of usage:

```
# open yesterdays journal
journ day -1day
journ day yesterday
 # if today is the 23rd
journ day 2020-09-22 

# open tommorows journal
journ day 1day
journ day tomorrow
journ +1day

# open next mondays journal
journ day next Monday

# open a weekly summary
Journ week next Monday # or any day that next week

```

## Outro

Now go out there buddy, and show the world how neat and tidy your life is (just don't let them look at the pile of dishes).

