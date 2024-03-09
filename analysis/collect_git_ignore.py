import os

# Configuration
directory_to_scan = os.getcwd()  # Use the current working directory
max_file_size = 1024 * 1024 * 1  # 1 MB size threshold
gitignore_path = os.path.join(directory_to_scan, '.gitignore')

# Function to add paths to .gitignore
def rewrite_gitignore(paths_to_ignore, gitignore_path):
    with open(gitignore_path, 'w') as gitignore_file:
        for path in paths_to_ignore:
            gitignore_file.write(f"{path}\n")
            print(f"Added to .gitignore: {path}")

# Collect large files and log directories
paths_to_ignore = []
for root, dirs, files in os.walk(directory_to_scan):
    # Check and add log directories
    if 'log' in root.split(os.sep) or 'logs' in root.split(os.sep) or 'incomplete' in root.split(os.sep) or 'metadata' in root.split(os.sep) or 'locks' in root.split(os.sep):
        relative_dir_path = os.path.relpath(root, directory_to_scan)
        paths_to_ignore.append(os.path.join(relative_dir_path, '*'))  # Ignore all files in log directories
        continue  # Skip further processing for these directories

    for name in files:
        file_path = os.path.join(root, name)
        relative_path = os.path.relpath(file_path, directory_to_scan)
        if os.path.getsize(file_path) > max_file_size:
            paths_to_ignore.append(relative_path)

# Rewrite .gitignore with the collected paths
if paths_to_ignore:
    rewrite_gitignore(paths_to_ignore, gitignore_path)
else:
    print("No files or log directories found to add to .gitignore.")

# The following lines are for committing the changes to the git repository
# They should be executed in the terminal or through a script that has access to git commands
# git add .gitignore
# git commit -m "Finalized snakefile to generate merged bam files by condition. Added large files and log directories to .gitignore."
# git push origin main

