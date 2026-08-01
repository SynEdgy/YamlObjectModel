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

The principle comes from Kubernetes resources. Independently serialized YOM
resources can describe their contract version, runtime type, metadata, and
typed specification:

```yaml
apiVersion: example.synedgy.com/v1alpha1
kind: ModuleName\ClassName
metadata:
  Name: example
  Labels:
    purpose: demonstration
spec:
  property1: value1
  property2: value2
```

`apiVersion` and `metadata` are optional for backward compatibility. When they
are unset, serialization omits them and retains the legacy `kind`/`spec` shape.
The module-qualified `kind` is preserved after dispatch.

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
    apiVersion = 'example.synedgy.com/v1alpha1'
    kind = 'MyModule\MyTest'
    metadata = @{
        Name = 'example'
    }
    spec = @{
        Property1 = 'thingy'
        Property2 = 'something else'
    }
})
```

When the caller already knows the expected type, it can supply a typed short
envelope that omits only `kind`:

```PowerShell
[YOMApiDispatcher]::DispatchSpec(
    'MyModule\MyTest',
    @{
        apiVersion = 'example.synedgy.com/v1alpha1'
        metadata = @{
            Name = 'example'
        }
        spec = @{
            Property1 = 'thingy'
            Property2 = 'something else'
        }
    }
)
```

Legacy raw-spec typed input and legacy `kind`/`spec` definitions remain
supported.

## Loading objects from files

`Get-YOMObject` loads one file, multiple YAML documents, or all `.yml` files
under a directory.

```powershell
$object = Get-YOMObject -Path .\resource.yml
```

Use `-DefaultType` when the document omits `kind`:

```powershell
$object = Get-YOMObject `
    -Path .\resource.yml `
    -DefaultType 'MyModule\MyTest'
```

The typed input may be either:

- an envelope containing `apiVersion`, `metadata`, and `spec`
- a legacy raw spec

The source path is assigned to `SavedAtPath` after construction when the object
supports that property. It is not inserted into portable `spec`.

## Nested typed objects

A property inside `spec` can contain another typed object:

```yaml
apiVersion: example.synedgy.com/v1alpha1
kind: MyModule\ParentResource
metadata:
  Name: parent
spec:
  Child:
    kind: MyModule\ChildResource
    spec:
      Value: child-value
```

`YOMBase.ResolveSpec()` identifies the nested `kind`, dispatches it, and retains
the resolved object in the internal specification model.

Embedded objects do not need their own `apiVersion` or `metadata` unless they
are independently meaningful resources.

## Serialization

Objects derived from `YOMBase` expose:

- `ToYaml()`
- `ToJson()`
- `ToString()`

```powershell
$yaml = $object.ToYaml()
$json = $object.ToJson()
```

Serialization preserves a dispatched module-qualified `kind`. It emits
`apiVersion` and `metadata` only when they contain values.

Object properties marked with `YamlIgnoreAttribute` are not copied into
`spec`.

## Saveable objects

Derive from `YOMSaveableBase` when an object should be persisted and reloaded:

```powershell
$object.SaveTo('.\resource.yml')
$object.Property1 = 'changed'
$object.Save()
$object.Reload()
```

`SaveTo()` sets `SavedAtPath`. `Save()` writes to that path, and `Reload()` reads
the current file back into the same object.

## Dispatch targets

`kind` can select:

- a class constructor
- a PowerShell function when the action contains `-`
- a static class method using `ClassName::Method`

For persistent resource contracts, module-qualified class kinds are generally
the most predictable option:

```yaml
kind: MyModule\MyResource
spec: {}
```

## Compatibility forms

### Kubernetes-style envelope

```yaml
apiVersion: example.synedgy.com/v1alpha1
kind: MyModule\MyResource
metadata:
  Name: example
spec:
  Property1: value1
```

### Legacy kind and spec

```yaml
kind: MyResource
spec:
  Property1: value1
```

### Typed envelope without kind

```yaml
apiVersion: example.synedgy.com/v1alpha1
metadata:
  Name: example
spec:
  Property1: value1
```

### Legacy raw spec

```yaml
Property1: value1
```

The last two forms require a caller-supplied default type.

## Error behavior

YamlObjectModel rejects:

- definitions without `kind` when no default type is available
- resource envelopes whose `spec` is not a dictionary
- non-dictionary metadata
- malformed module-qualified dispatch actions

Errors are surfaced rather than converted into partially initialized objects.
