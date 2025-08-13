read -p "Enter Email : " email

if [[ $email =~ ^[a-zA-Z0-9.%_+-]+@[a-zA-Z.-]+\.[a-z]{2,}$ ]]
then
    echo "valid Email"
else 
    echo "Invalid Email"
fi