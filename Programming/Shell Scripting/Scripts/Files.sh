<<comment
# Create multiple Dirs and check if created 

mkdir dir_1 dir_2 dir_3

if [ $? -ne 0 ]
then
    echo "Created"
else 
    echo "Failed to Create"
fi

comment

source_dir="./Folder/"

destination_dir="./destination_dir/"

mkdir -p "$destination_dir"

cp -R $source_dir/* $destination_dir/

if [ $? -eq 0 ]; then
    echo "Files copied successfully."
else
    echo "Failed to copy files."
fi




