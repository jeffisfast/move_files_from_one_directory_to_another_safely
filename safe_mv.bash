#!/bin/bash

# This script moves all files from a source directory to a destination directory individually,
# only removing the file from the source directory if the move was successful.  In addition, it will
# not overwrite a file in the destination directory if a file with the same name already exists, instead it will 
# rename it.  The script will also skip any files that are currently open.

# Function to print the progress bar
print_progress() {
    local current=$1
    local total=$2
    local progress=$((current * 100 / total))
    local currentfile=$3
    local remainingfiles=$((total - current))

    printf '\033[1A\033[K'
    printf "Progress: ["
    for ((i = 0; i < progress / 2; i++)); do
        printf "#"
    done
    for ((i = progress / 2; i < 50; i++)); do
        printf " "
    done
    printf "] %d%%" "$progress" 
    printf " $remainingfiles $currentfile\n"
    
}


# Check if the correct number of arguments is provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <source_directory> <destination_directory>"
    exit 1
fi

# Assign source and destination directories from the arguments
src_dir="$1"
dest_dir="$2"

counter=0
errorcounter=0
renamecounter=0
skipcounter=0

# Check if the source directory exists
if [ ! -d "$src_dir" ]; then
    echo "Error: Source directory '$src_dir' does not exist."
    exit 1
fi

# Create the destination directory if it doesn't exist
mkdir -p "$dest_dir"

# Count the number of files in the source directory
total_files=$(find "$src_dir" -maxdepth 1 -type f | wc -l)
processed_files=0

echo "\nMoving $total_files files from $src_dir to $dest_dir.\n\n"

# Loop through the files in the source directory
for file in "$src_dir"/*; do
    # Check if it's a file
    if [ -f "$file" ]; then
        if lsof -t "$file" > /dev/null; then
            echo "\nSkipping open file: $file\n\n"
            skipcounter=$((skipcounter+1))
        else
            # Get the file's name and extension
            filename=$(basename "$file")
            name="${filename%.*}"
            ext="${filename##*.}"

            # Set destination file path
            dest_file="$dest_dir/$filename"

            # Check for existing files with the same name in the destination directory
            samefilecount=1
            while [ -e "$dest_file" ]; do
                echo "\nFile '$dest_file' already exists, renaming.\n\n"
                dest_file="$dest_dir/${name}_$samefilecount.$ext"
                samefilecount=$((samefilecount + 1))
            done
            
            if [ $samefilecount -gt 1 ]; then
                renamecounter=$((renamecounter+1))
            fi

            # Move the file to the destination directory
            mv "$file" "$dest_file"

            # Check if the move was successful
            if [ ! $? -eq 0 ]; then
                echo "\nError: Failed to move $file to $dest_file.\n\n"
                errorcounter=$((errorcounter+1))
            else
                counter=$((counter+1))
            fi
        fi
    fi
    # Update progress
    processed_files=$((processed_files + 1))
    print_progress "$processed_files" "$total_files" "$dest_file"
done

echo "\n. Done. \nMoved $counter files."
echo "Renamed $renamecounter files."
echo "Failed to move $errorcounter files."
echo "Skipped $skipcounter files."
