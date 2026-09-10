# Vim — Complete Reference

> Vim is a modal text editor — it has distinct modes, each with different key behaviors. Once you internalize the modes, it's faster than any GUI editor for text manipulation. Essential for editing files on remote servers where no GUI is available.

---

## Modes

| Mode | How to enter | Indicator | Purpose |
|------|-------------|-----------|---------|
| **Normal** | `Esc` (always) | (no indicator) | Navigate, delete, copy, paste commands |
| **Insert** | `i`, `a`, `o`, `I`, `A`, `O` | `-- INSERT --` | Type text |
| **Visual** | `v`, `V`, `Ctrl+v` | `-- VISUAL --` | Select text for operations |
| **Command** | `:` | `:` at bottom | Save, quit, search/replace, settings |
| **Search** | `/` or `?` | `/` at bottom | Forward/backward search |

---

## Navigation — Normal Mode

```
# ─── Basic movement ───────────────────────────────────────────────
h j k l         ← ↓ ↑ →  (use these instead of arrow keys)
w               move forward one word (start)
b               move backward one word (start)
e               move to end of word

# ─── Line movement ───────────────────────────────────────────────
0               go to start of line
^               go to first non-whitespace character
$               go to end of line
gg              go to first line of file
G               go to last line of file
:100            go to line 100
50G             go to line 50
Ctrl+g          show current line number and file info

# ─── Screen movement ─────────────────────────────────────────────
Ctrl+d          scroll down half screen
Ctrl+u          scroll up half screen
Ctrl+f          scroll forward (page down)
Ctrl+b          scroll backward (page up)
zz              center current line on screen
```

---

## Insert Mode — Entering Text

```
i               insert before cursor
a               append after cursor
I               insert at start of line (I = big i, goes to first non-space)
A               append at end of line
o               open new line BELOW and enter insert mode
O               open new line ABOVE and enter insert mode
s               delete character under cursor and insert
S               delete entire line and insert
```

---

## Editing — Normal Mode

```
# ─── Delete ──────────────────────────────────────────────────────
x               delete character under cursor
dd              delete (cut) current line
5dd             delete 5 lines
dw              delete word from cursor
D               delete from cursor to end of line
dG              delete from current line to end of file

# ─── Copy (yank) and paste ────────────────────────────────────────
yy              yank (copy) current line
5yy             yank 5 lines
yw              yank word
y$              yank to end of line
p               paste AFTER cursor/line
P               paste BEFORE cursor/line

# ─── Change ──────────────────────────────────────────────────────
cc              delete line and enter insert mode
cw              change word (delete + insert)
C               change from cursor to end of line
r<char>         replace single character with <char>

# ─── Undo / Redo ──────────────────────────────────────────────────
u               undo
Ctrl+r          redo
.               repeat last change command

# ─── Indentation ─────────────────────────────────────────────────
>>              indent line right
<<              indent line left
```

---

## Visual Mode — Select and Operate

```
v               character-wise visual select
V               line-wise visual select (selects whole lines)
Ctrl+v          block/column visual select

# After selecting:
y               yank (copy) selection
d               delete selection
>               indent selection
<               unindent selection
~               toggle case

# Insert at start of multiple lines (column edit):
Ctrl+v → select lines → I → type text → Esc  (inserts on every selected line)
```

---

## Search and Replace

```
# ─── Search ─────────────────────────────────────────────────────
/pattern        search forward
?pattern        search backward
n               next match
N               previous match
*               search for word under cursor (forward)

# ─── Search and Replace (Command mode) ───────────────────────────
:s/old/new/         replace first occurrence on current line
:s/old/new/g        replace all occurrences on current line
:%s/old/new/g       replace ALL occurrences in entire file
:%s/old/new/gc      replace all with confirmation (y/n per match)
:%s/old/new/gi      case-insensitive replace all
:10,20s/old/new/g   replace on lines 10-20

# ─── Useful patterns ─────────────────────────────────────────────
:%s/\s\+$//         remove trailing whitespace from all lines
:%s/^/    /         indent every line by 4 spaces
```

---

## Command Mode — Save, Quit, Settings

```
# ─── Save and quit ───────────────────────────────────────────────
:w              write (save) file
:q              quit (fails if unsaved changes)
:q!             quit WITHOUT saving (discard changes)
:wq             save and quit
:x              save and quit (only writes if changed)
ZZ              save and quit (Normal mode shortcut)
ZQ              quit without saving (Normal mode shortcut)

# ─── Multiple files / splits ──────────────────────────────────────
vim -o file1 file2       open files in horizontal splits
vim -O file1 file2       open files in vertical splits
:split filename          open file in horizontal split
:vsplit filename         open file in vertical split
Ctrl+w h/j/k/l           move between splits
Ctrl+w w                  cycle between splits

# ─── Display settings ────────────────────────────────────────────
:set nu             show line numbers
:set nonu           hide line numbers
:set syntax on      enable syntax highlighting
:set expandtab      use spaces instead of tabs
:set tabstop=4      set tab width to 4 spaces
:set paste          disable auto-indent when pasting from clipboard
:set nopaste        re-enable auto-indent

# ─── Useful shortcuts ────────────────────────────────────────────
:!ls -la            run shell command without leaving vim
:r !date            insert command output at cursor
:w !sudo tee %      save file with sudo (when you forgot to open as root)
```

---

## Interview Q&A

**Q: How do you exit vim without saving?**
Press `Esc` to ensure you're in Normal mode, then type `:q!` — the `!` forces quit and discards unsaved changes. This is one of the most famous "interview" questions because it trips up anyone who hasn't used vim. Shortcut from Normal mode: `ZQ`.

**Q: How do you search and replace all occurrences in a file?**
`:%s/old/new/g` — `%` applies to all lines (without it, only the current line is affected), `s` is substitute, `g` means global (all occurrences per line). Add `c` for confirmation before each replacement: `:%s/old/new/gc`. Add `i` for case-insensitive: `:%s/old/new/gi`.

**Q: How do you delete multiple lines at once?**
`5dd` deletes 5 lines starting from the current line. Or: enter line-wise Visual mode with `V`, select the range with `j`, then press `d`. The deleted lines go to the default register and can be pasted with `p`.

**Q: What's the fastest way to go to a specific line?**
`:100` in Command mode, or `100G` in Normal mode. `gg` goes to line 1, `G` goes to the last line. `:set nu` first to see line numbers if they're not visible.
