import sys
import os
import shutil
import filecmp

from setuptools import setup
from setuptools.command.build_py import build_py

if sys.platform != "linux":
    raise RuntimeError("This package only supports Linux operating systems")


class PrepareLists(build_py):
    @staticmethod
    def get_all_files(directory):
        """Recursively get all files inside a directory."""
        all_files = {}
        for root, _, files in os.walk(directory):
            for file in files:
                if not file.endswith(".list"):
                    continue
                if file in all_files:
                    print(f"Error: Duplicate file name detected - {file} in {root} and {all_files[file]}")
                    sys.exit(1)
                all_files[file] = os.path.join(root, file)
        return all_files

    @staticmethod
    def copy_files(source_dir, target_dir):
        """Copy .list files from source_dir subdirectories to target_dir, preserving names."""
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)

        # Get all .list files ensuring unique names
        unique_files = PrepareLists.get_all_files(source_dir)

        for file_name, source_path in unique_files.items():
            target_path = os.path.join(target_dir, file_name)

            if os.path.exists(target_path):
                if filecmp.cmp(source_path, target_path, shallow=False):
                    print(f"Skipping {file_name}: Identical file already exists in target.")
                else:
                    print(f"Overwriting {file_name}: File contents differ.")
                    shutil.copy2(source_path, target_path)
            else:
                print(f"Copying new file {file_name} to target directory.")
                shutil.copy2(source_path, target_path)

    """ Custom build command that runs `prepare()` before building. """
    def run(self):
        PrepareLists.copy_files("lists", "nftlist-lists/data")  # Call the prepare function before proceeding with the build
        super().run()


setup(
    cmdclass = {"build_py": PrepareLists}
)


