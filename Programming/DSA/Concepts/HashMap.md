# HashMap (Go Map) — Complete Reference

> A HashMap (Go: `map`) is a data structure that stores key-value pairs. It provides O(1) average-case lookup, insertion, and deletion. One of the most frequently used data structures in interviews — essential for problems that need fast lookups, frequency counting, grouping, or duplicate detection.

---

## Go Map Fundamentals

```go
// ─── Declaration ──────────────────────────────────────────────────
var m map[string]int        // nil map — READ-ONLY, writes cause panic!
m = make(map[string]int)    // initialized empty map — safe to write

// Short form:
m := make(map[string]int)

// With literal values:
m := map[string]int{
    "alice": 25,
    "bob":   30,
}

// ─── CRUD operations ─────────────────────────────────────────────
m["key"] = 42              // insert/update
val := m["key"]            // read (returns zero value if key missing)
delete(m, "key")           // delete key-value pair
n := len(m)                // number of key-value pairs

// ─── Check if key exists ─────────────────────────────────────────
val, ok := m["key"]        // ok=true if key exists, ok=false if not
if ok {
    fmt.Println(val)
}
_, ok = m["key"]           // just check existence (discard value)

// ─── Nil map gotcha ───────────────────────────────────────────────
var m map[string]int        // m == nil
v := m["key"]              // OK — returns 0 (zero value)
m["key"] = 1               // PANIC: assignment to entry in nil map
// Fix: always initialize with make() or a map literal
```

---

## Iteration

```go
// Iterate over all key-value pairs
// Note: Go map iteration order is RANDOM (intentional randomness)
for key, val := range m {
    fmt.Println(key, val)
}

// Iterate over keys only
for key := range m {
    fmt.Println(key)
}

// Sorted iteration (need to sort keys first)
keys := make([]string, 0, len(m))
for k := range m {
    keys = append(keys, k)
}
sort.Strings(keys)
for _, k := range keys {
    fmt.Println(k, m[k])
}
```

---

## Common Interview Patterns

```go
// ─── Pattern 1: Frequency counting ───────────────────────────────
func frequencyCount(nums []int) map[int]int {
    freq := make(map[int]int)
    for _, n := range nums {
        freq[n]++         // += 1 for each occurrence; starts at 0 if key missing
    }
    return freq
}

// Use case: find the most frequent element
func mostFrequent(nums []int) int {
    freq := make(map[int]int)
    maxCount, result := 0, nums[0]
    for _, n := range nums {
        freq[n]++
        if freq[n] > maxCount {
            maxCount, result = freq[n], n
        }
    }
    return result
}

// ─── Pattern 2: Check for duplicates ──────────────────────────────
func hasDuplicate(nums []int) bool {
    seen := make(map[int]bool)
    for _, n := range nums {
        if seen[n] {
            return true
        }
        seen[n] = true
    }
    return false
}
// Alternative: use map[int]struct{} as a memory-efficient set

// ─── Pattern 3: Two Sum pattern (complement lookup) ───────────────
func twoSum(nums []int, target int) []int {
    seen := make(map[int]int)   // value → index
    for i, n := range nums {
        if j, ok := seen[target-n]; ok {
            return []int{j, i}
        }
        seen[n] = i
    }
    return nil
}

// ─── Pattern 4: Grouping / anagram grouping ───────────────────────
func groupAnagrams(strs []string) [][]string {
    groups := make(map[string][]string)
    for _, s := range strs {
        key := sortString(s)      // sorted chars = key for anagram group
        groups[key] = append(groups[key], s)
    }
    result := make([][]string, 0, len(groups))
    for _, g := range groups {
        result = append(result, g)
    }
    return result
}

// ─── Pattern 5: Character frequency for string comparison ─────────
func isAnagram(s, t string) bool {
    if len(s) != len(t) {
        return false
    }
    freq := make(map[rune]int)
    for _, c := range s {
        freq[c]++
    }
    for _, c := range t {
        freq[c]--
        if freq[c] < 0 {
            return false
        }
    }
    return true
}
```

---

## Map vs Slice vs Set — When to Use Which

| Data Structure | Use when | Time complexity |
|---|---|---|
| **Map** | Fast key lookup, key-value association, counting | O(1) avg lookup/insert |
| **Slice** | Ordered collection, index access, sequential processing | O(n) search, O(1) index |
| **Set (map[T]struct{})** | Membership testing only, no value needed | O(1) avg lookup |
| **Sorted slice** | Ordered data, binary search needed | O(log n) search |

```go
// Memory-efficient set in Go (empty struct has 0 bytes):
seen := make(map[int]struct{})
seen[42] = struct{}{}
_, exists := seen[42]        // true

// vs map[int]bool (uses 1 byte per bool):
seen := make(map[int]bool)
seen[42] = true
exists := seen[42]
```

---

## HashMap Internals — How It Works

```
HashMap = array of buckets + hash function

Insert "alice":
  1. hash("alice") → 0x4a2f → mod bucket_count → bucket index 3
  2. Store ("alice", val) in bucket 3

Lookup "alice":
  1. hash("alice") → bucket index 3
  2. Search bucket 3 for key "alice"
  3. Return value

Hash collision: two keys hash to same bucket
  → Go uses chaining: bucket holds a linked list of key-value pairs
  → Multiple collisions = O(n) worst case (hash DoS attack)
  → Go randomizes hash seeds per-process to prevent hash flooding attacks

Load factor: when too many entries, Go grows the map (allocates new, larger array)
  → ~50-100% load factor before growth
  → Growth causes temporary O(n) rehashing but amortized O(1) insert
```

---

## Pros, Cons, and Trade-offs

**Advantages:**
- O(1) average-case lookup, insert, delete — much faster than linear search O(n)
- Flexible key types (any comparable type in Go: string, int, struct without slices/maps/functions)
- Built-in zero value behavior: uninitialized reads return the zero value

**Disadvantages:**
- Unordered — iteration order is random; use a sorted slice of keys if order matters
- Higher memory overhead than slices (metadata, hash buckets)
- Worst-case O(n) lookup when many hash collisions occur (rare with good hash functions)
- Not safe for concurrent use — need `sync.Map` or `sync.RWMutex` for goroutine safety

**Concurrent map:**
```go
// sync.Map — concurrent-safe but slower for single-goroutine use
var m sync.Map
m.Store("key", 42)
val, ok := m.Load("key")
m.Delete("key")
m.Range(func(k, v interface{}) bool {
    fmt.Println(k, v)
    return true   // return false to stop iteration
})
```

---

## Interview Q&A

**Q: What happens if you read from an uninitialized (nil) map in Go?**
Reading from a nil map is safe — it returns the zero value for the value type (0 for int, "" for string, false for bool, nil for pointers). Writing to a nil map panics: `panic: assignment to entry in nil map`. Always initialize with `make(map[K]V)` or a map literal before writing. This is a common interview gotcha — many candidates confuse read and write behavior.

**Q: Why is Go map iteration order random?**
The Go team intentionally randomized map iteration order (added in Go 1.0) to prevent programmers from depending on insertion order (which is an implementation detail that could change). The randomization uses a random seed per `range` loop start. If you need deterministic output, sort the keys first: `sort.Strings(keys)` then iterate by index. This is a real interview question and also a common bug in production code.

**Q: When would you use `map[int]struct{}` instead of `map[int]bool`?**
`struct{}` is an empty struct — it occupies 0 bytes. `bool` occupies 1 byte. For a large set with millions of entries, this matters. More importantly, using `struct{}` communicates semantic intent clearly: "this is a Set, I only care whether the key exists, not any associated value." `map[int]bool` could be mistakenly read as "bool means something meaningful." Idiomatic Go: use `struct{}` for sets. Practical: for small sets in interviews, either is fine.

**Q: What's the time complexity of map operations?**
Average case: O(1) for insert, lookup, and delete. This is because a good hash function distributes keys uniformly across buckets, making each bucket very short (O(1) to search). Worst case: O(n) when there are many hash collisions (all keys land in the same bucket). Go randomizes hash seeds to prevent adversarial inputs from forcing O(n) behavior. For interview purposes: say O(1) average, and mention the worst case if asked about adversarial scenarios.
