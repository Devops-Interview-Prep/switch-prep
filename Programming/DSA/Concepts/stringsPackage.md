# Function for Searching & Matching

- `strings.Contains(s, substr)`     ->  Check if substr exists in s

- `strings.HasPrefix(s, prefix)`	->  Check if s starts with prefix

- `strings.HasSuffix(s, suffix)`	->  Check if s ends with suffix

- `strings.Index(s, substr)`	    ->  Returns index of substr in s, or -1

- `strings.Count(s, substr)`	    ->  Count occurrences of substr in s

```
strings.Contains("hello world", "world")     // true
strings.HasPrefix("hello", "he")             // true
strings.Index("banana", "na")                // 2
```

# Functions for Modification & Transformation

- `strings.ToUpper(s)`                  -> 	Convert to uppercase
  
- `strings.ToLower(s)`	                ->  Convert to lowercase

- `strings.Trim(s, cutset)`             ->	Remove leading/trailing characters in cutset

- `strings.ReplaceAll(s, old, new)`     ->	Replace all occurrences

- `strings.Repeat(s, count)`	        ->  Repeat string multiple times

```
strings.ToUpper("go")         // "GO"
strings.Trim("  space  ", " ") // "space"
strings.ReplaceAll("ha ha", "ha", "ho") // "ho ho"
```

# Functions for Splitting & Joining

- `strings.Split(s, sep)`	            ->  Split string into slice

- `strings.Join(slice, sep)`	        ->  Join slice into string

- `strings.Fields(s)`	                ->  Split by any whitespace

- `strings.SplitN(s, sep, n)`	        ->  Split into n parts

```
parts := strings.Split("a,b,c", ",")      // ["a", "b", "c"]
str := strings.Join(parts, "-")           // "a-b-c"
words := strings.Fields("go lang fun")   // ["go", "lang", "fun"]
```

# Functions for Comparison

- strings.EqualFold(a, b)	            ->  Case-insensitive comparison

```
strings.EqualFold("Go", "go") // true
```