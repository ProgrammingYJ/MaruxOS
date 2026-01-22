#!/usr/bin/env python3
# Modify GTK gresources XML generator to remove to-pixdata preprocessing

import sys

filepath = sys.argv[1] if len(sys.argv) > 1 else "gtk/gen-gtk-gresources-xml.py"

with open(filepath, "rb") as f:
    content = f.read()

# The pattern in the file is literally: preprocess=\'to-pixdata\'
# In bytes: preprocess=\x5c'to-pixdata\x5c'
# We need to remove: space + preprocess=\'to-pixdata\'
old_pattern = b" preprocess=\\'to-pixdata\\'"
new_pattern = b""

count = content.count(old_pattern)
print(f"Found {count} occurrences of the pattern")

content = content.replace(old_pattern, new_pattern)

with open(filepath, "wb") as f:
    f.write(content)

print(f"Modified {filepath} - removed {count} instances of to-pixdata preprocessing")
