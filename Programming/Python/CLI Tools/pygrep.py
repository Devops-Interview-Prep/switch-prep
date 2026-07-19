#!/usr/bin/env python3


import argparse
import re 

def search_pattern(file, regex, show_line_number, inverted_match, count) :
    with open(file) as f:
        for line_number, line in enumerate(f, start=1):
                if inverted_match :
                    if not regex.search(line) :
                        if show_line_number :
                            print(f"{file}: {line_number} : {line}", end="")
                        else :
                            print(f"{file}: {line}", end="")
                else :
                    if count :
                        matches = list(regex.finditer(line))
                        search_count = len(matches) 
                        if search_count > 0 :
                            if show_line_number :
                                print(f"{file}: {line_number} : {search_count}")
                            else :
                                print(f"{file}: {line} : {search_count}")
                    else :
                        if regex.search(line) :
                            if show_line_number :
                                print(f"{file}: {line_number} : {line}", end="")
                            else :
                                print(f"{file}: {line} : {line}", end="")



def main():
    parser = argparse.ArgumentParser(description="pygrep Tool")

    # found = False

    show_line_number = False

    parser.add_argument("pattern" , help="word to search")
    parser.add_argument("files" , help="file name to search inside", nargs = "+")
    parser.add_argument("-n", action="store_true" ,help= "shows line numbers")
    parser.add_argument("-i", action="store_true", help="for finding case insensitive results")
    parser.add_argument("-v", action="store_true" ,help= "shows lines which doesnt have the pattern")
    parser.add_argument("-c", action="store_true" ,help= "count number of matches per line")


    args = parser.parse_args()

    if args.i :
        flag = re.IGNORECASE
    else :
        flag = 0

    if args.n :
        show_line_number = True

    regex = re.compile(args.pattern,flag)

    for file in args.files:
        search_pattern(file, regex, show_line_number, args.v, args.c )


if __name__ == "__main__":
    main()








