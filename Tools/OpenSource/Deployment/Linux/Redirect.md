# File Descriptors

- It is an integer that represents an open file
- Types:
  - Standard Input(stdin)   -> File Descriptor 0
  - Standard Output(stdout) -> File Descriptor 1
  - Standard ERR(stderr)    -> File Descriptor 2
- These discriptors help the system understand where to send or recieve the data 


# Redirection 

- `>`   output redirection
- `>>`  append outputs in the file
- `2>`  Error Redirection
- `2>>` Append error outputs
- `&>`  Both output and error redirection 
- `&>>` Append output or error both 

- `<` file input redirection
- `<<EOF` multiline input redirection