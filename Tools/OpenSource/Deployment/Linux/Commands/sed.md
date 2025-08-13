# sed

`sed [OPTIONS] 'command' file`

- sed is a non-interactive text editor
- It reads text line by line, applies editing commands, and outputs the result.

**Common Use Cases**

- Find and replace text
- Delete lines
- Insert/append lines
- Print specific lines
- Transform characters

**Most Common sed Commands**

| Command           | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `s/pattern/repl/` | Substitute `pattern` with `repl` (like find & replace) |
| `d`               | Delete the line                                        |
| `p`               | Print the line (used with `-n`)                        |
| `a\text`          | Append `text` after a line                             |
| `i\text`          | Insert `text` before a line                            |
| `c\text`          | Change the whole line to `text`                        |
| `y/set1/set2/`    | Transform characters (like `tr`)                       |

**Useful sed Options**

| Option          | Meaning                                            |
| --------------- | -------------------------------------------------- |
| `-n`            | Suppress automatic printing (useful with `p`)      |
| `-e`            | Add multiple `sed` commands                        |
| `-i[SUFFIX]`    | Edit files **in-place** (optionally create backup) |
| `-f script.sed` | Use a sed script file                              |


- show only a given line or range of lines
  - `sed -n '1p' file_name`
  - `sed -n '1,5p' file_name`   will print 1 to 5th line
  - `sed -n '$p' file_name`     will print last line

- Show the lines containing India
  - `sed -n '/India/p' file_name`

- use multiple expression in sed command 
  - `sed -n -e '2p' -e '5p' file_name` prints 2nd and 5th line

- see next 4 lines from 2nd line
  - `sed -n ‘2,+4p’ file_name`

- see every 2nd line from first line
  - `sed -n ‘1~2p’ file_name`

- read expression from external file
  - `sed -f ex_file file_name`  write the expressions like 1p,3p etc in external file

- How to replace a word in a file and show?
  - `sed 's/<string_to_change>/<new_string>/g' file_name`

- replace a word in a file and show except a given line or only in given line
  - `sed '5 s/<string_to_change>/<new_string>/g' file_name`
  - `sed '5! s/<string_to_change>/<new_string>/g' file_name`

- replace a word and and edit in your file
  - `sed -i's/<string_to_change>/<new_string>/g' file_name`

- delete a line
  - `sed '1d' file_name`
  - `sed '1,2d' file_name`
  - `sed '$d' file_name`
- 

