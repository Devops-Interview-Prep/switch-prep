

regex="^(\+?[0-9]{1,3}[-.\s]?)?(\(?[0-9]{3}\)?[-.\s]?)?[0-9]{3}[-.\s]?[0-9]{4}$"

read -p "enter phone number: " number

if [[ $number =~ $regex ]]
then
    echo "valid phone number"
else
    echo "Invalid Phone number"
fi