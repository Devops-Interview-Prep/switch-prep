#!/opt/homebrew/bin/bash

string="A man, a plan, a canal: Panama"

newString=$( echo "${string,,}" | tr -cd a-z )

reverseString=$( echo "$newString" | rev )

if [ $newString == $reverseString ]
then 
    echo "Its a Palindrome"
else
    echo "Its not a Palindrome"
fi