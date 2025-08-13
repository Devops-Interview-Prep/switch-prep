# tr

-  Translate, squeeze, or delete characters from input streams.
-  It works only on characters, not on whole strings or lines.

`tr [OPTIONS] SET1 [SET2]`

- SET1: input characters
- SET2: replacement characters
- Both sets must be the same length, unless you're deleting or squeezing characters.

| Option | Meaning                                            |
| ------ | -------------------------------------------------- |
| `-d`   | Delete characters in SET1                          |
| `-s`   | Squeeze repeated characters in SET1 into one       |
| `-c`   | Complement SET1 (match characters **not** in SET1) |

- Convert lowercase to uppercase

`tr 'a-z' 'A-Z' < file.txt`

- Convert uppercase to lowercase

`tr 'A-Z' 'a-z' < file.txt`

- Replace spaces with underscores

`tr ' ' '_' < file.txt`

- Delete specific characters (e.g., !)

`tr -d '!' < file.txt`

- Delete all digits

`tr -d '0-9' < file.txt`

- Squeeze multiple spaces into one

`tr -s ' ' < file.txt`

- Delete everything except letters

`tr -cd 'a-zA-Z' < file.txt`


**Special Character Classes**

| Class       | Matches                              |
| ----------- | ------------------------------------ |
| `[:lower:]` | All lowercase letters                |
| `[:upper:]` | All uppercase letters                |
| `[:alpha:]` | All alphabetic characters            |
| `[:digit:]` | All digits                           |
| `[:alnum:]` | All alphanumeric characters          |
| `[:space:]` | All whitespace (space, tab, etc.)    |
| `[:punct:]` | All punctuation                      |
| `[:cntrl:]` | Control characters (e.g. `\n`, `\t`) |


- `tr '[:lower:]' '[:upper:]' < file.txt`
- `echo "abc123" | tr -d '0-9'`


# sed

