# Quick Examples: Tested Patterns

All examples in this guide are based on working code from the test files.

## Setup

```foxpro
* Load the libraries
DO pyfox_libs.prg

* Create and initialize Python host
LOCAL loPy
loPy = CREATEOBJECT("PythonHost")
loPy.LoadPythonDLL()
```

## JSON Processing

### Parse JSON to Native VFP Types

```foxpro
LOCAL loPy, lcJson, loPyJsonObj, loNative
loPy = CREATEOBJECT("PythonHost")
loPy.LoadPythonDLL()

lcJsonDict = '{"name": "Alice", "age": 30, "friends": ["Bob", "Charlie"], "meta": {"score": 85.6, "active": true}}'

* Get Python wrapper object
loPyJsonObj = loPy.PythonFunctionCall('json', 'loads', CREATEOBJECT('PythonTuple', lcJsonDict))

* Convert to native VFP
loNative = _PyFoxNative(loPyJsonObj)

* Access values
? 'Collection count:', loNative.Count
? 'Value for name:', _PyFoxGetPairValue(loNative, 'name')
? 'Value for age:', _PyFoxGetPairValue(loNative, 'age')

* Access nested list
LOCAL loFriends, item
loFriends = _PyFoxGetPairValue(loNative, 'friends')
IF VARTYPE(loFriends) == 'O'
    FOR EACH item IN loFriends
        ? 'Friend: ', item
    ENDFOR
ENDIF
```

### Parse JSON List

```foxpro
LOCAL loPy, lcJsonList, loPyJsonList, loNativeList, itm
loPy = CREATEOBJECT("PythonHost")
loPy.LoadPythonDLL()

lcJsonList = '["apple", "banana", 3, {"nested": "obj"}]'

loPyJsonList = loPy.PythonFunctionCall('json', 'loads', CREATEOBJECT('PythonTuple', lcJsonList))
loNativeList = _PyFoxNative(loPyJsonList)

IF VARTYPE(loNativeList) == 'O'
    ? 'List count:', loNativeList.Count
    FOR EACH itm IN loNativeList
        ? 'Item type:', VARTYPE(itm), 'Value:', itm
    ENDFOR
ENDIF
```

### Get Native Values from Pairs

```foxpro
LOCAL loPy, lcJson, loNative, lsName, lnAge
loPy = CREATEOBJECT("PythonHost")
loPy.LoadPythonDLL()

lcJson = '{"name": "Alice", "age": 30}'

loPyJsonObj = loPy.PythonFunctionCall('json', 'loads', CREATEOBJECT('PythonTuple', lcJson))
loNative = _PyFoxNative(loPyJsonObj)

* Convert to native scalar values
lsName = _PyFoxGetVal(_PyFoxGetPairValue(loNative, 'name'))
lnAge = _PyFoxGetVal(_PyFoxGetPairValue(loNative, 'age'))

? 'Name (native string):', lsName
? 'Age (native number):', lnAge
```

## More Help

- **Need detailed setup?** See [GETTING_STARTED.md](GETTING_STARTED.md)
