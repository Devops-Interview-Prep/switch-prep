
# Rename all .txt to .bak

#!/bin/bash

find . -type f -name "*.txt" -exec bash -c 'for f in $@;do mv "$f" "${f%.txt}.bak"; done' _ {} +