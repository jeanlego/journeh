# Journ'eh?

## What is it

> Do you wish you were better organized and you live in the terminal. 
> Do you wish you could write a daily 'memoir' like all those pro out there just going full ham.
> 
> Look no more son! I got the tool for you, journeh: A french canadian tool, like it's author.
> This is the outcome of smashing the french word "Journee" with the canadianism "Eh?"
>
> Journ'eh?, a tool to organize your daily shenanigans, even by quarters for you BA afficionados.


## Usage

| commands | effect |
| -- | -- |
|    `init <git url>`           |       this will init the repo for remote backup.  |
|    `day  [date -d arguments]`  |      create a daily journal entry.  |
|    `week [date -d arguments]`   |     create a weekly-end journal entry. | 
|    `month [date -d arguments]`   |    create a month-end journal entry.  |
|    `quarter [date -d arguments]`  |   create a quarter-end journal entry. | 
|    `year [date -d arguments]`      |  create a year-end journal entry.  |
|    `help`                           | this.  |

For the date arguments, see the [gnu core util `date` --date input format](https://www.gnu.org/software/coreutils/manual/html_node/Date-input-formats.html#Date-input-formats)

### Example

Some (but not limited) quick example of usage:

#### open yesterdays journal

```bash
journ day -1day
journ -1day
journ day yesterday
 # if today is the 23rd
journ day 2020-09-22
```

#### open todays journal

```bash
journ
journ day 
```

#### open period journal

```bash
journ 1day 8day
journ
```


#### open tommorow journal

```bash
journ day 1day
journ day tomorrow
journ +1day
```

#### open next mondays journal

```bash
journ day next monday
```

#### open a weekly summary

```bash
journ week next monday
```

---

New journal entry will be populated from the `template.md` located in `$HOME/.journeh`, then $PWD, then where the source for the tool is located.

The `template.md` is bash expanded upon usage for each new entry.
The variable is used with `$VAR` or `${VAR}`.

All the variables from `journ.sh` are currently exposed, here are some the ones available:

| variable | value |
| -- | -- |
| `PERIOD` | the current period value (for a day, full date, a week, the year and the week number, etc...) |

## Outro

Now go out there buddy, and show the world how neat and tidy your life is (just don't let them look at the pile of dishes).

