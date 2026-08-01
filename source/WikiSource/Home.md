# YamlObjectModel

<sup>*YamlObjectModel v#.#.#*</sup>

YamlObjectModel is a PowerShell framework for projecting YAML or JSON
definitions into typed objects and serializing those objects back into portable
resource documents.

## Core capabilities

- Kubernetes-style `apiVersion`, `kind`, `metadata`, and `spec` envelopes
- module-qualified dynamic dispatch
- nested typed objects
- typed short-form loading
- legacy input compatibility
- YAML and JSON serialization
- save, reload, and file discovery

## Resource model

```yaml
apiVersion: example.synedgy.com/v1alpha1
kind: MyModule\MyResource
metadata:
  Name: example
spec:
  Property1: value1
```

The dispatcher uses `kind` to load the source module and create the selected
class from `spec`. `apiVersion` and `metadata` remain available on the resulting
object and are preserved when it is serialized again.

Unset `apiVersion` and empty `metadata` are omitted, preserving the legacy
`kind`/`spec` output for existing object models.

## Start here

- [Using YamlObjectModel](Using-YamlObjectModel)

That page explains class authoring, resource dispatch, short forms, nested
objects, file loading, serialization, and backward compatibility.
