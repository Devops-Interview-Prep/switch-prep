#!/bin/bash

read -p "Enter password: " pass
echo

if [[ $pass =~ ^(.*[a-z])(.*[A-Z])(.*[0-9])(.*[@#$%^&+=]).{8,}$ ]]
then
  echo "Strong password"
else
  echo "Weak password"
fi
