# py-fox: Python/VFP Bridge

![License](https://img.shields.io/badge/license-MIT-blue)
![Status](https://img.shields.io/badge/status-active-brightgreen)

**Seamlessly execute Python code from Visual FoxPro. Leverage the full power of Python's ecosystem within your VFP applications.**

py-fox is a comprehensive bridge that enables Visual FoxPro applications to call Python functions, handle Python objects, and integrate Python libraries directly into your VFP codebase. With automatic type conversion, robust error handling, and support for complex Python data structures, py-fox makes Python-VFP interoperability simple and intuitive.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [Usage Examples](#usage-examples)
- [Documentation](#documentation)
- [Architecture](#architecture)
- [Attribution](#attribution)
- [Contributing](#contributing)
- [License](#license)

## Features

✨ **Type Conversion**
- Automatic bidirectional conversion between VFP and Python native types (strings, numbers, booleans, dates)
- Seamless handling of Python lists, tuples, and dictionaries
- Support for complex nested structures

🐍 **Python Integration**
- Call any Python module and function directly from VFP
- Access Python object attributes and methods
- Iterate over Python collections using VFP's FOR EACH syntax
- Full JSON support with native VFP parsing and Python json module integration

🔧 **Error Handling**
- Python exceptions are automatically captured and raised as VFP errors
- Detailed error messages with tracebacks for debugging
- Structured error reporting

⚙️ **Flexibility**
- Support for multiple Python versions (3.6, 3.8, 3.10, 3.12+)
- Embedded Python DLL support
- Virtual environment compatibility
- Both synchronous execution models

## Requirements

- **Visual FoxPro** 8.0 or later (VFP 9.0 recommended)
- **Python** 3.6 or later (3.12+ tested)
  - Either system-wide installation, virtual environment, or embedded Python folder
- **Windows** (32-bit - Python 3.6+ 32-bit)

## Quick Start

### 1. Setup

#### Option A: System Python
```powershell
# Download Python from python.org or use your existing installation
# Ensure Python is in your PATH or note the installation directory
```

#### Option B: Virtual Environment (Recommended)
```powershell
# Create a virtual environment
python -m venv .venv

# Activate it
.\.venv\Scripts\Activate.ps1

# Install required packages
pip install -r requirements.txt
```

#### Option C: Embedded Python
```powershell
# Place the Python folder (Python312-32, etc.) in your project directory
# or reference it explicitly in your VFP code
```

### 2. Initialize in VFP

```foxpro
* Create the Python host object
LOCAL loPy
loPy = CREATEOBJECT("PythonHost")

* Load the Python DLL
loPy.LoadPythonDLL()  && Uses default path
* OR specify a custom path:
loPy.LoadPythonDLL("C:\path\to\python312.dll")

* Now you can call Python!
LOCAL loResult
loResult = loPy.PythonFunctionCall('json', 'loads', CREATEOBJECT('PythonTuple', '{"name": "Alice"}'))
? loResult.repr()
```

### 3. Basic Usage

```foxpro
* Call a Python function
LOCAL loPy, loRandom
loPy = CREATEOBJECT("PythonHost")
loPy.LoadPythonDLL()

loRandom = loPy.PythonFunctionCall('random', 'randint', CREATEOBJECT('PythonTuple', 5, 20))
? 'Random number:', loRandom.getval()

* Work with JSON
LOCAL lcJson, loData
lcJson = '{"users": [{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]}'
loData = loPy.PythonFunctionCall('json', 'loads', CREATEOBJECT('PythonTuple', lcJson))

* Convert to native VFP types for easier handling
LOCAL loNative
loNative = _PyFoxNative(loData)
? loNative.Count  && Number of key-value pairs
```

## Core Concepts

### Wrapper Objects
When Python returns complex objects, they're wrapped in a VFP object (`PythonObjectImpl`) that provides methods to interact with the Python object while maintaining reference semantics.

```foxpro
* Get a wrapper object
LOCAL loPyObj
loPyObj = loPy.PythonFunctionCall('json', 'loads', ...)

* Check if it's a wrapper
IF VARTYPE(loPyObj) == 'O'
  * Access methods and attributes
  ? loPyObj.CallMethodRetObj('keys', CREATEOBJECT('PythonTuple'))
  ? loPyObj.getitem('mykey')
ENDIF
```

### Native Conversion
Use `_PyFoxNative()` to convert Python objects to native VFP types (Collections, strings, numbers) for easier handling in VFP code.

```foxpro
* Python dict -> VFP Collection of pairs
LOCAL loPyDict, loVfpCollection
loPyDict = loPy.PythonFunctionCall('json', 'loads', '{"a": 1, "b": 2}')
loVfpCollection = _PyFoxNative(loPyDict)

* Access values using helper function
? _PyFoxGetPairValue(loVfpCollection, 'a')  && Returns: 1
```

## Documentation

Comprehensive documentation is available in the `/documentation` folder:

- **[Getting Started Guide](documentation/GETTING_STARTED.md)** - Detailed setup and configuration
- **[Quick Examples](documentation/QUICK_EXAMPLES.md)** - Common patterns and use cases

See the `/test` folder for additional working examples in `pyfox_test_json.prg`.

## Architecture

```
py-fox/
├── classes/
│   ├── pyfox/              # Core Python host implementation
│   │   ├── pyfox_host.prg
│   │   ├── pyfox_wrapper.prg
│   │   └── pyfox_helpers.prg
│   ├── json/               # JSON parsing utilities
│   ├── bases/              # Base classes and utilities
│   └── tools/              # Helper tools
├── python/                 # Embedded Python (optional)
├── documentation/          # Detailed guides
├── test/                   # Test files
└── README.md               # This file
```

## Attribution

This project is a refactored version of [VFP-Embedded-Python](https://github.com/mwisslead/VFP-Embedded-Python) by [@mwisslead](https://github.com/mwisslead). The original project provided the foundational framework for embedding Python within Visual FoxPro applications, which has been extended and refactored with improved structure, documentation, and features.

## Contributing

Contributions are welcome! Please feel free to:
- Report issues and bugs
- Suggest improvements and features
- Submit pull requests with enhancements
- Improve documentation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Ready to get started?** See the [Getting Started Guide](documentation/GETTING_STARTED.md) for detailed instructions.
