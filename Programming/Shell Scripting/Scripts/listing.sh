
cd folder
find . -empty -type f -exec ls -lah {} +

#find . -type d -maxdepth 1

<<comment

cd folder
for file in .* *
do 
    if [[ -f $file ]]
    then
        echo "$file"
    fi
done

comment

<<comment

if [[ $# -lt 1 ]]
then   
    echo "dir name not provided"
else   
    dir_name=$1
    ls $dir_name
fi 

comment

