

<<comment
grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}"

-E for enabling regex in echo
-o to match exact output not the whole line 

comment


read -p "Enter an IP: " ip

if [[ $ip =~ (^[0-9]{1,3}\.){3}[0-9]{1,3}$ ]]
then 
    echo "valid IP"
else 
    echo "Invalid IP"
fi