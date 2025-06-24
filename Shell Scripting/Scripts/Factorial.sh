

read -p "Enter a number: " num
factorial=1

if [[ $num =~ ^[0-9]+$ ]]
then 
    while [[ $num -ne 0 ]]
    do 
        let factorial=$num*$factorial
        let num--
    done
    echo "$factorial"
else 
    echo "Please enter a valid Number"
fi

