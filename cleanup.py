import os


def cleanup_files(directory, extensions):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if any(file.endswith(ext) for ext in extensions):
                file_path = os.path.join(root, file)
                print(f"Removing file: {file_path}")
                os.remove(file_path)


# remove inkscape folder and all files in it

def remove_inkscape_folder():
    os.system(f"rm -rf  svg-inkscape")
    print(f"Removed inkscape folder")

if __name__ == "__main__":
    current_directory = os.getcwd()
    extensions_to_cleanup = ['.log', '.aux', '.fls', '.fdb_latexmk', ".out"]
    cleanup_files(current_directory, extensions_to_cleanup)
    remove_inkscape_folder()
    print("Cleanup completed.")


