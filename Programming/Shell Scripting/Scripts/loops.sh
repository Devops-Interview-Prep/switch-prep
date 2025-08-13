<<comment
# Iterate over a range of numbers from 1 to 20
for ((i = 1; i <= 20; i++)); do
    # Check if the current number is odd
    if ((i % 2 != 0))
    then
        echo "$i"
    fi
done
comment

<<comment

# Write a Bash script that utilizes a while loop to continuously generate a random number between 1 and 50 
# until it generates a number divisible by 3.

while [[ 1 ]]
do
    num=$(( RANDOM%50 + 1 ))
    if (( $num%3 == 0))
    then
        echo "$num"
        exit 1
    fi
done

comment

<<comment

password="xyz"
while [[ 1 ]]
do
    stty -echo
    read -p "Enter the password: " pass
    stty echo
    if [[ $pass == $password ]]
    then
        echo "Password is correct"
        exit 1
    else 
        echo "Wrong Password, Enter Again !"
    fi
done

comment

names=("Iolanda" "Valeri" "Sheela" "Jana" "Hartwig")

# Iterate over the list of names using a for loop
for name in "${names[@]}"
do
    echo "Hello, $name! Welcome to the Bash script."
done

<<comment
for i in {0..10}
do 
echo "$i"
done
comment

<<comment
# Print table of number

read -p "write a number: " number
if [[ $number =~ ^[0-9]+$ ]]
then 
    i=1
    while [ $i -le 10 ]
    do 
        let x=$i*$number
        echo "$x"
        let i++
    done
else
    echo "Enter a valid Integer"
fi
comment

<<comment
# Return file names 

for file in *
do 
    if [[ -f $file ]]
    then
        echo "$file"
    fi
done
comment