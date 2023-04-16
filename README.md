# move_files_from_one_directory_to_another_safely

This script moves all files in the source_folder to the destination_folder but is safer than just doing mv src/ dest/ because it:
- won't move open files
- will rename files before they overwrite an existing file with the same at the destination

I use this script as part of an automated backup strategy that regularly moves files to a separate backup hard drive.
