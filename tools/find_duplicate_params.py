"""
Script: find_duplicate_params.py
Purpose: Find VFP PRG/PRG-like files where functions declare parameter lists in both
- the function signature (e.g. FUNCTION foo(a,b)) and
- an immediate `LPARAMETERS a,b` line.
This helps prevent duplicate parameter declarations that could confuse readers and
may be inconsistent.
"""
import re, glob

matches = []
for p in glob.glob('**/*.prg', recursive=True):
    with open(p, 'r', encoding='latin1') as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        if 'LPARAMETERS' in line:
            # check previous 1-5 lines for FUNCTION with parentheses
            prev = ''.join(lines[max(0, i-5):i+1])
            m = re.search(r'FUNCTION\s+([A-Za-z0-9_]+)\([^\)]*\)', prev, re.IGNORECASE)
            if m:
                # record location
                # include snippet of the signature line and LPARAMETERS line
                sig_line = m.group(0).strip()
                param_line = lines[i].strip()
                matches.append((p, i+1, sig_line, param_line))

if matches:
    print('Found occurrences of both FUNCTION signature + LPARAMETERS:')
    for p, lineno, sig, param in matches:
        print(f"{p}: line {lineno}: {sig}  |  {param}")
else:
    print('No duplicates found (good).')
