#!/usr/bin/env python3
import sys

filepath = sys.argv[1] if len(sys.argv) > 1 else "gtk/gen-gtk-gresources-xml.py"

with open(filepath, "r") as f:
    content = f.read()

# Replace preprocess='to-pixdata' with empty string
content = content.replace(" preprocess='to-pixdata'", "")

with open(filepath, "w") as f:
    f.write(content)

print(f"Modified {filepath} - removed to-pixdata preprocessing")
