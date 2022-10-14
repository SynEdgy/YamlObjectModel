# Using YamlObjectModel

This module is meant to be used as a base to create PowerShell classes where
its derived objects can be serialised and deserialised to YAML or JSON.

It uses (and depends on) YamlDotNet through the PowerShell-Yaml module to
do the conversion.


## Base classes

This module contains base classes you can inherit from in your project to
consistently enable the following features:

- `[YOMBase]`: Base class that provides custom serialisation with a Kind and its spec.
  It also exposes the following:
    - `[string] ToYaml()` method
    - `[string] ToString()` method
    - `[string] ToJson()` method
    - `hidden [void] ResolveSpec([IDictionary] $definition)` method
    - `hidden [void] ResolveSpec([string]$kind, [IDictionary] $definition)` method

- `[YOMSaveable]`: Base class that extends `[YOMBase]` to also offer:
    - `SaveTo([string]$Path)` method: Serialise the object to the file `$Path`.
      Once saved to a path, the object has the property `SavedAtPath` set to the absolute path of that file.
    - `Save()` method: Once the object has been saved to a file (with `SaveTo()`), you can re-save without specifying the destination.
    - `LoadFromFile([string]$Path)` method: You can load the properties of an object from a file containing the serialised object or just the properties configured as default.
      Once loaded from file the object has the property `SavedAtPath` set to the absolute path of that file, and
      can the methods `Save()` and `Reload()` can be used.
    - `Reload()` method: This will read the properties from the file and set them on the object.
      It's particularly useful when an object might have been changed by a human, and you want your script to pick it up while it's still running. 


## API Dispatcher

The API dispatcher (`[YOMApiDispatcher]::DispatchSpec()`) is a couple of static methods with different overrides that can take a definition (deserialised YAML or hashtable with the type name).

The principle comes from Kubernetes objects that are persisted in Yaml through its `spec`, and describe their type
via a `kind` property.
```yaml
kind: ClassName
spec:
  property1: value1
  property2: value2
```

With the following class defined in PowerShell:
```PowerShell
using namespace System.Collections
using namespace System.Collections.Specialized
using module YamlObjectModel
using namespace YamlDotNet.Serialization

class MyTest : YOMSaveableBase
{
    [string] $Property1
    [string] $Property2

    MyTest()
    {
        # Default Ctor()
    }

    MyTest([IDictionary] $Definition)
    {
        # constructor for hashtable/Ordered Dictionary
        $this.ResolveSpec($Definition) # Common method coming from YOMBase
    }

    [string] GetString()
    {
      '{0} and {1}' -f $this.Property1,$this.Property2
    }
}

```
We can create an instance by calling the dispatcher like so:

```PowerShell
[YOMApiDispatcher]::DispatchSpec(@{
    kind = MyTest
    spec = @{
        Property1 = 'thingy'
        Property2 = 'something else'
    }
})
```
We can also
