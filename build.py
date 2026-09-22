import subprocess
import shutil
import sys
from pathlib import Path

def main():
    root = Path(__file__).parent.resolve()
    print("[*] Building MkDocs documentation...")
    subprocess.run([sys.executable, "-m", "mkdocs", "build", "--strict"], cwd=root, check=True)

    landing_src = root / "landing.html"
    index_dst = root / "site" / "index.html"

    print(f"[*] Injecting interactive landing page into {index_dst}...")
    shutil.copyfile(landing_src, index_dst)
    print("[+] Build successful! Interactive landing page is live at root index.html.")

if __name__ == "__main__":
    main()
