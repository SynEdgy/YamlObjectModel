# YamlObjectModel

[![Build Status](https://dev.azure.com/synedgy/YamlObjectModel/_apis/build/status/SynEdgy.YamlObjectModel?branchName=main)](https://dev.azure.com/synedgy/YamlObjectModel/_build)
[![codecov](https://codecov.io/gh/SynEdgy/YamlObjectModel/branch/main/graph/badge.svg)](https://codecov.io/gh/SynEdgy/YamlObjectModel)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/YamlObjectModel?label=YamlObjectModel%20Preview)](https://www.powershellgallery.com/packages/YamlObjectModel/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/YamlObjectModel?label=YamlObjectModel)](https://www.powershellgallery.com/packages/YamlObjectModel/)
[![License](https://img.shields.io/github/license/SynEdgy/YamlObjectModel)](LICENSE)

YamlObjectModel is a PowerShell framework for building typed object models that
serialize to and from YAML or JSON.

It provides:

- Kubernetes-style `apiVersion`, `kind`, `metadata`, and `spec` resource
  envelopes
- module-qualified dynamic type dispatch
- nested typed-object resolution
- typed short-form loading when the caller knows the expected type
- backward compatibility with legacy raw specs and `kind`/`spec` definitions
- base classes for YAML/JSON serialization
- save, reload, and file-loading support

## Install

```powershell
Install-PSResource -Name YamlObjectModel
Import-Module -Name YamlObjectModel
```

`Install-Module` can also be used on systems using PowerShellGet.

## Resource envelope

An independently serialized YOM resource can be represented as:

```yaml
apiVersion: example.synedgy.com/v1alpha1
kind: MyModule\MyResource
metadata:
  Name: example
  Labels:
    environment: test
spec:
  Property1: value1
  Property2: value2
```

The fields have distinct responsibilities:

| Field | Purpose |
| --- | --- |
| `apiVersion` | Version of the serialized resource contract |
| `kind` | Module-qualified class, function, or static dispatch action |
| `metadata` | Identity, labels, annotations, and discovery information |
| `spec` | Constructor input for the selected type |

`apiVersion` and `metadata` are optional. When unset, serialization emits the
legacy-compatible `kind`/`spec` shape.

## Define a YOM class

```powershell
using namespace System.Collections
using module YamlObjectModel

class MyResource : YOMSaveableBase
{
    [string] $Property1
    [string] $Property2

    MyResource()
    {
    }

    MyResource([IDictionary] $Definition)
    {
        $this.ResolveSpec($Definition)
    }
}
```

Modules can expose their classes through type accelerators, allowing a
module-qualified `kind` to import the module and construct the corresponding
type.

## Dispatch a resource

```powershell
$resource = [YOMApiDispatcher]::DispatchSpec([ordered] @{
    apiVersion = 'example.synedgy.com/v1alpha1'
    kind = 'MyModule\MyResource'
    metadata = [ordered] @{
        Name = 'example'
    }
    spec = [ordered] @{
        Property1 = 'value1'
        Property2 = 'value2'
    }
})
```

The dispatcher imports `MyModule` when necessary, invokes the selected
constructor with `spec`, and preserves the resource envelope on the resulting
object.

## Typed short form

When a command already knows the expected type, the input can omit `kind`:

```yaml
apiVersion: example.synedgy.com/v1alpha1
metadata:
  Name: example
spec:
  Property1: value1
  Property2: value2
```

```powershell
$resource = Get-YOMObject `
    -Path .\resource.yml `
    -DefaultType 'MyModule\MyResource'
```

Legacy raw-spec typed input remains supported:

```yaml
Property1: value1
Property2: value2
```

## Serialize and save

Objects deriving from `YOMBase` provide:

```powershell
$resource.ToYaml()
$resource.ToJson()
$resource.ToString()
```

Objects deriving from `YOMSaveableBase` also provide:

```powershell
$resource.SaveTo('.\resource.yml')
$resource.Save()
$resource.Reload()
```

`SavedAtPath` is runtime state and is not added to the portable `spec`.

## Compatibility

YamlObjectModel accepts:

1. Kubernetes-style resource envelopes
2. legacy `kind`/`spec` definitions
3. typed envelopes without `kind` when a default type is supplied
4. legacy raw specs when a default type is supplied

This allows existing modules to migrate without rewriting all serialized
objects at once.

## Documentation

- [Using YamlObjectModel](source/WikiSource/Using-YamlObjectModel.md)
- [YamlObjectModel Wiki](https://github.com/SynEdgy/YamlObjectModel/wiki)
- [Change log](CHANGELOG.md)

## Build and test

```powershell
.\build.ps1 -ResolveDependency -Tasks noop
.\build.ps1 -Tasks build
.\build.ps1 -Tasks test
```

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Contributing

Please review the common
[DSC Community contributing guidelines](https://dsccommunity.org/guidelines/contributing).
