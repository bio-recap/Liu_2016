# Create or append to a .gitignore file in the current directory
with open('.gitignore', 'a') as gitignore:
    # Add a new line for readability if the file already exists and is not empty
    gitignore.seek(0, 2)  # Move the cursor to the end of the file
    if gitignore.tell():  # Check if the file is not empty
        gitignore.write('\n')  # Start from a new line
    
    # Ignore everything in the "public" directory
    gitignore.write('public/*\n')

print("Updated .gitignore with 'public/*'")
