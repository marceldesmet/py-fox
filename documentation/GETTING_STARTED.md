# Getting Started with py-fox

This guide will walk you through setting up py-fox in your Visual FoxPro project step by step.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [Installation Options](#installation-options)
3. [Setup Steps](#setup-steps)
4. [Verify Installation](#verify-installation)
5. [Troubleshooting](#troubleshooting)
6. [Next Steps](#next-steps)

## System Requirements

### Minimum Requirements
- **Visual FoxPro** 8.0 or later
  - VFP 9.0 (SP2+) is recommended
  - Both 32-bit and 64-bit versions are supported
  - Professional or Enterprise edition

- **Windows** 7 SP1 or later (32-bit)
  - Windows 10, 11 recommended

- **Python** 3.6 or later (32-bit only)
  - 3.8, 3.10, 3.12+ tested and verified
  - **Important**: Must be Python 32-bit version

### Recommended Setup
```
VFP 9.0 (32-bit) + Python 3.12 (32-bit)
```

## Installation Options

Choose ONE of the following approaches:

### Option 1: System-Wide Python (Simplest)

**Pros**: Easy setup, useful for development  
**Cons**: Requires Python in PATH, affects global Python environment

**Steps**:
1. Download Python 32-bit from [python.org](https://www.python.org/downloads/)
   - Must be 32-bit version
   - Example: `python-3.12.1.exe` (select 32-bit during installation)

2. Run the installer:
   - ✅ Check "Add Python 3.12 to PATH" (important!)
   - ✅ Check "Install for all users" (optional but recommended)
   - Choose installation directory (default is fine)

3. Verify installation:
   ```powershell
   python --version
   python -c "import struct; print(f'{8 * struct.calcsize(\"P\")} bit')"
   ```
   Should output: `32 bit`

4. Note the Python installation path (e.g., `C:\Python312`)

### Option 2: Virtual Environment (Recommended for Projects)

**Pros**: Isolated dependencies, reproducible, clean project setup  
**Cons**: Slightly more setup, but worth it

**Steps**:

1. First, install base Python (follow Option 1 steps 1-2)

2. Create a virtual environment in your project directory:
   ```powershell
   cd "C:\Path\To\Your\VFP\Project"
   python -m venv .venv
   ```

3. Activate the environment:
   ```powershell
   # Windows PowerShell
   .\.venv\Scripts\Activate.ps1
   
   # Or if using Command Prompt
   .venv\Scripts\activate.bat
   ```

4. Install any required packages:
   ```powershell
   pip install requests beautifulsoup4  # Example packages
   ```

5. Note the path to python.exe:
   ```powershell
   .\.venv\Scripts\python.exe
   ```

### Option 3: Embedded Python (Advanced - For Distribution)

**Pros**: Self-contained, easy to distribute, no system Python required  
**Cons**: Larger file size, more manual setup

**Steps**:

1. Download embedded Python:
   - Go to [python.org/downloads](https://www.python.org/downloads/)
   - Look for "Windows embeddable package"
   - Match your VFP bitness!
   - Example: `python-3.12.1-embed-amd64.zip` (64-bit)

2. Extract to your project:
   ```powershell
   Expand-Archive python-3.12.1-embed-amd64.zip
   Rename-Item python-3.12.1-embed-amd64 python312
   ```

3. Your project structure:
   ```
   YourProject/
   ├── python312/           # Extracted embedded Python
   ├── classes/
   │   └── pyfox/
   ├── YourForm.scx
   └── YourMain.prg
   ```

4. Note the path: `C:\Path\To\YourProject\python312`

## Setup Steps

### Step 1: Copy py-fox Files to Your Project

```powershell
# Copy the pyfox classes directory to your project
Copy-Item -Path "c:\Public Github\py-fox\classes\pyfox" -Destination "C:\Your\Project\classes\" -Recurse

# Verify files exist
Get-ChildItem "C:\Your\Project\classes\pyfox" -Filter "*.prg"
```

Expected files:
- `pyfox_host.prg`
- `pyfox_wrapper.prg`
- `pyfox_helpers.prg`
- Any .FXP compiled versions

### Step 2: Update VFP Project Settings

Open your VFP project (.pjx) and add the pyfox classes:

**In VFP IDE**:
1. Project → Add → File
2. Navigate to `classes/pyfox/pyfox_host.prg`
3. Repeat for `pyfox_wrapper.prg` and `pyfox_helpers.prg`

**Or manually in code**:
```foxpro
* Include at the start of your main program
DO LOCFILE("classes/pyfox/pyfox_host.prg")
DO LOCFILE("classes/pyfox/pyfox_wrapper.prg")
DO LOCFILE("classes/pyfox/pyfox_helpers.prg")
```

### Step 3: Configure Python Path in Your Code

Create a configuration file or update your initialization code:

**In your main program or startup routine**:

```foxpro
* Initialize Python
FUNCTION InitPython()
    LOCAL loPy, lcPythonPath
    
    * Choose based on your setup:
    
    * Option 1: System Python (in PATH)
    lcPythonPath = "C:\Python312\python312.dll"
    
    * Option 2: Virtual Environment
    * lcPythonPath = ".\.venv\Scripts\python312.dll"
    
    * Option 3: Embedded Python
    * lcPythonPath = ".\python312\python312.dll"
    
    loPy = CREATEOBJECT("PythonHost")
    
    IF FILE(lcPythonPath)
        loPy.LoadPythonDLL(lcPythonPath)
        RETURN loPy
    ELSE
        ERROR "Python DLL not found at: " + lcPythonPath
    ENDIF
ENDFUNC

* Usage in your code:
LOCAL loPy
loPy = InitPython()
```

## Verify Installation

### Test 1: Basic Python Call

Create a test program `test_python.prg`:

```foxpro
SET PROCEDURE TO classes/pyfox/pyfox_host.prg
SET PROCEDURE TO classes/pyfox/pyfox_wrapper.prg ADDITIVE
SET PROCEDURE TO classes/pyfox/pyfox_helpers.prg ADDITIVE

LOCAL loPy, loResult

TRY
    loPy = CREATEOBJECT("PythonHost")
    loPy.LoadPythonDLL()
    
    ? "✓ Python host created successfully"
    ? "✓ Python DLL loaded successfully"
    
    * Test 1: Simple number return
    loResult = loPy.PythonFunctionCall('random', 'randint', CREATEOBJECT('PythonTuple', 1, 100))
    ? "✓ Called random.randint():", loResult.getval()
    
    * Test 2: JSON parsing
    loResult = loPy.PythonFunctionCall('json', 'loads', CREATEOBJECT('PythonTuple', '{"test": true}'))
    ? "✓ Called json.loads():", loResult.repr()
    
    ? ""
    ? "All tests passed! py-fox is ready to use."
    
CATCH TO loError
    ? "✗ Error:", loError.Message
    ? "Details:", loError.Details
ENDTRY
```

Run it:
```powershell
CD C:\Your\Project
vfp test_python.prg
```

### Test 2: Check Python Version

```foxpro
LOCAL loPy, loVersion
loPy = CREATEOBJECT("PythonHost")
loPy.LoadPythonDLL()

loVersion = loPy.PythonFunctionCall('sys', 'version', CREATEOBJECT('PythonTuple'))
? "Python version:", loVersion.getval()
```

## Troubleshooting

### Problem: "Python DLL not found"

**Solution**:
1. Verify Python is installed: `python --version`
2. Check the DLL exists: `Get-ChildItem "C:\Python312\python312.dll"`
3. Verify bitness matches your VFP
4. Use absolute path instead of relative path

```foxpro
* Wrong
loPy.LoadPythonDLL()

* Right
loPy.LoadPythonDLL("C:\Python312\python312.dll")
```

### Problem: "Error: 126" or "Error: 127"

**Meaning**: DLL found but cannot be loaded (missing dependencies)

**Solution**:
1. Verify Python is 32-bit version
2. Install Visual C++ Redistributable 32-bit for your Python version
3. Use Windows Dependency Walker to check for missing DLLs:
   ```powershell
   # Download depends.exe or use from Visual Studio
   depends "C:\Python312\python312.dll"
   ```

### Problem: "Module not found" error

**Example**: `ImportError: No module named 'requests'`

**Solution**:
```powershell
# For system Python
python -m pip install requests

# For virtual environment
.\.venv\Scripts\python.exe -m pip install requests
```

### Problem: py-fox classes not found

**Solution**:
1. Verify files are copied:
   ```powershell
   Get-ChildItem classes/pyfox -Filter "*.prg"
   ```

2. Make sure procedures are loaded:
   ```foxpro
   DO LOCFILE("classes/pyfox/pyfox_host.prg")
   DO LOCFILE("classes/pyfox/pyfox_wrapper.prg")
   DO LOCFILE("classes/pyfox/pyfox_helpers.prg")
   
   ? "pyfox_host class exists:", TYPE("PythonHost") != "U"
   ```

### Problem: "License error" or "Activation required"

This is a VFP licensing issue, not py-fox related. Use VFP license that supports CREATEOBJECT() with external DLLs.

## Next Steps

Once you've verified installation:

1. **Read the Quick Examples**: See [QUICK_EXAMPLES.md](QUICK_EXAMPLES.md)
2. **Explore the Tests**: Check `/test/pyfox_test_json.prg`
3. **Start Building**: Create your first integration!

### Recommended First Projects

**Project 1: JSON Processing**
```foxpro
* Parse JSON from web service and display in form
LOCAL lcJson, loData
lcJson = GetJsonFromApi()  && Your function
loData = loPy.PythonFunctionCall('json', 'loads', CREATEOBJECT('PythonTuple', lcJson))
```

**Project 2: Data Validation**
```foxpro
* Use Python validators library for email/URL validation
loPy.PythonFunctionCall('validators', 'email', CREATEOBJECT('PythonTuple', 'user@example.com'))
```

**Project 3: CSV Processing**
```foxpro
* Parse CSV with Python's csv module
loPy.PythonFunctionCall('csv', 'reader', ...)
```

---

## Support & Resources

- **Documentation**: See the `documentation/` folder
- **Examples**: Check `/test/` folder for working code
- **Questions**: Review existing documentation first

Happy coding with py-fox! 🐍
