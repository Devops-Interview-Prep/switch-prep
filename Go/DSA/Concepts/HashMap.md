# Introduction

One of the most useful data structures in computer science is the hash table. Many hash table implementations exist with varying properties, but in general they offer fast lookups, adds, and deletes. Go provides a built-in map type that implements a hash table.

# Declaration and initialization

`map[KeyType]ValueType`

Ex. `var m map[string]int`

This variable m is a map of string keys to int values

- Map types are reference types, like pointers or slices, and so the value of m above is nil; it doesn’t point to an initialized map. A nil map behaves like an empty map when reading, but attempts to write to a nil map will cause a runtime panic; don’t do that. 

- In Go, initializing a map means creating a new map and allocating memory for it before you can use it to store key-value pairs. You need to initialize a map before you can assign values to it — otherwise, you'll get a runtime panic.

- Because a nil map in Go:
  - has no underlying memory allocation
  - cannot be written to — attempting to add a key-value pair will cause a runtime error:
panic: assignment to entry in nil map

- To initialize a map, use the built in make function:

    `m = make(map[string]int)`

# Working with maps

- Go provides a familiar syntax for working with maps. This statement sets the key "route" to the value 66:

    `m["route"] = 66`

- This statement retrieves the value stored under the key "route" and assigns it to a new variable i:

    `i := m["route"]`

- If the requested key doesn’t exist, we get the value type’s zero value. In this case the value type is int, so the zero value is 0:

    `j := m["root"]`   
    `// j == 0`

- The built in len function returns on the number of items in a map:
  
    `n := len(m)`

- The built in delete function removes an entry from the map:

    `delete(m, "route")`

- A two-value assignment tests for the existence of a key:

    `i, ok := m["route"]`

    In this statement, the first value (i) is assigned the value stored under the key "route". If that key doesn’t exist, i is the value type’s zero value (0). The second value (ok) is a bool that is true if the key exists in the map, and false if not.

    To test for a key without retrieving the value, use an underscore in place of the first value:   

    `_, ok := m["route"]`

- To iterate over the contents of a map, use the range keyword:

```
for key, value := range m {
    fmt.Println("Key:", key, "Value:", value)
}
```

- To initialize a map with some data, use a map literal:

```
commits := map[string]int{
    "rsc": 3711,
    "r":   2138,
    "gri": 1908,
    "adg": 912,
}
```

- The same syntax may be used to initialize an empty map, which is functionally identical to using the make function:

`m = map[string]int{}`

