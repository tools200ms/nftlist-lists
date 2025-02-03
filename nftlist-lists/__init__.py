import os
import shutil
from importlib.resources import files

DEST_DIR = "/var/lib/nftlist"
SOURCE_DIR = files("nftlist-lists").joinpath("data")

def ensure_data_installed():
    """Ensure that data files are placed in /var/lib/nftlist."""
    if not os.path.exists(DEST_DIR):
        os.makedirs(DEST_DIR)
    for file in SOURCE_DIR.iterdir():
        target_path = os.path.join(DEST_DIR, file.name)
        if not os.path.exists(target_path):
            shutil.copy(file, target_path)

ensure_data_installed()
