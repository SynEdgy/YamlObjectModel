using namespace YamlDotNet.Core
using namespace YamlDotNet.Serialization
using namespace YamlDotNet.Core.Events
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Collections.Specialized

class YOMBase : IYamlConvertible
{
    [YamlIgnoreAttribute()]
    hidden [string] $kind
    [YamlIgnoreAttribute()]
    hidden [OrderedDictionary] $spec

    YOMBase()
    {
        # empty ctor
    }

    YOMBase([IDictionary]$RawSpec)
    {
        $this.ResolveSpec($RawSpec)
    }

    [void] Read([IParser] $Parser, [Type] $Type, [ObjectDeserializer] $NestedObjectDeserializer)
    {
        # TODO
        # This is to parse Yaml to this object when we use an annotation registered with the parser
        # I don't think that's possible with PowerShell-Yaml yet.
    }

    [void] Write([IEmitter] $Emitter, [ObjectSerializer] $NestedObjectSerializer)
    {
        # TODO: Look in the Type Accelerators.
        # if $this.GetType() has a corresponding TypeAccelerator that is fully qualified, the beginning
        # of the name is probably the module.
        # What if there's a "category" in between though?

        $fullTypeName = $this.GetType().FullName
        $kindValue = $fullTypeName
        $typeAccelerator = Get-YOMAcceleratorKeyFromType -Type $fullTypeName
        if ($dynamicClassAttribute = @($this.GetType().Assembly.CustomAttributes).Where{
                $_.AttributeType.FullName -eq 'System.Management.Automation.DynamicClassImplementationAssemblyAttribute'
            })
        {
            # No type accelerator found, maybe the class is only defined within a module without export
            # Search if the type of the object has a custom attributes that defines the script of the module
            # TODO: Test with nested module, although that's a bit of a stretch
            $scriptFile = @($dynamicClassAttribute[0].NamedArguments).Where{$_.MemberName -eq 'ScriptFile'}.TypedValue.Value

            if (-not [string]::IsNullOrEmpty($scriptFile))
            {
                $module = (Get-Module).Where{$_.Path -eq $scriptFile}
                $kindValue = '{0}\{1}' -f $Module.Name, $fullTypeName
            }
            else
            {
                $kindValue = $fullTypeName
            }
        }
        elseif (-not [string]::IsNullOrEmpty($typeAccelerator.key))
        {
            # A Type accelerator was found.
            if ($typeAccelerator.Key.length -gt $typeAccelerator.Value.FullName.length -and $typeAccelerator.Key -match '\.')
            {
                # The TypeAccelerator is longer than the full name and contains ".",
                # it's likely a PowerShell defined class from a module to which we've added
                # the moduleName as prefix to mimic a namespace. [ModuleNamePart1.ModuleNamePart2.Category.TypeName]
                # try to infer the module it's from
                $fullTypeName = $typeAccelerator.Key
                $modulePart, $ClassName = $fullTypeName -split '\.',-2

                $moduleFound = $false
                $loadedModules = Get-Module
                while ($modulePart -match '\.' -and -not $moduleFound)
                {
                    if ($loadedModules.Where{
                        $_.Name -eq $modulePart
                    })
                    {
                        $moduleFound = $true
                    }
                    else
                    {
                        $modulePart, $null = $modulePart -split '\.',-2
                    }
                }

                if ($moduleFound)
                {
                    $kindValue = '{0}\{1}' -f $modulePart,$fullTypeName
                }
                else
                {
                    $kindValue = $fullTypeName
                }
            }
        }
        else
        {
            $kindValue = $this.GetType().ToString() # Problem here is that we don't know which module it's coming from...
        }

        $outerObject = [ordered]@{
            kind = $kindValue
            spec = [ordered]@{}
        }

        $this.PSObject.Properties.Where({
            $_.Name -in $this.GetType().GetProperties().Where{$_.CustomAttributes.AttributeType -ne [YamlDotNet.Serialization.YamlIgnoreAttribute]}.name -and
            $true -eq $_.IsSettable}).Foreach{
                if ($_.Value -is [scriptblock])
                {
                    # Otherwise the .Invoke() method conflicts between the serializer and
                    # the IYamlConvertible interface (so best to convert to string before)
                    $outerObject.spec.Add($_.Name,$_.Value.ToString())
                }
                else
                {
                    $outerObject.spec.Add($_.Name,$_.Value)
                }
        }

        $NestedObjectSerializer.Invoke($outerObject)
    }

    hidden [void] ResolveSpec([string] $kind, [IDictionary] $RawSpec)
    {
        #TODO: Should we go get the fully qualified kind as we do during serialization?
        $this.Kind = $RawSpec.kind
        $this.ResolveSpec($RawSpec)
    }

    hidden [void] ResolveSpec([IDictionary] $RawSpec)
    {
        if (-not [string]::IsNullOrEmpty($RawSpec.kind))
        {
            $this.ResolveSpec($RawSpec.kind,$RawSpec.Spec)
        }
        else
        {
            if (-not [string]::IsNullOrEmpty($this.kind))
            {
                $this.kind = $RawSpec.kind
            }

            $this.Spec = [Ordered]@{}

            foreach ($keyInSpec in $RawSpec.Keys)
            {
                Write-Debug -Message "Testing value of [$keyInSpec] for object definition..."
                $ValueForSpec = if ([YOMApiDispatcher]::IsDefinition($RawSpec.($keyInSpec)))
                {
                    # value is a nested object definition
                    Write-Debug -Message "Resolving value as an object."
                    [YOMApiDispatcher]::DispatchSpec($RawSpec.($keyInSpec))
                }
                else #TODO: make sure you have an elseif() when the object is a 'shorthand' of an object (handler or object)
                {
                    # Value is not a hash with kind, return as-is
                    Write-Debug -Message "The Value is --->$($RawSpec.($keyInSpec))"
                    $RawSpec.($keyInSpec)
                }

                $this.Spec.Add($keyInSpec,$ValueForSpec)
                if ($this.PSObject.Properties.Item($keyInSpec).issettable)
                {
                    $this.($keyInSpec) = $RawSpec.($keyInSpec)
                }
            }

        }
    }

    hidden [void] _setProperties([IDictionary] $Definition)
    {
        $this.psobject.properties.Where{$_.IsSettable -and $_.Name -in $Definition.Keys}.Name.Foreach{
            if ($null -ne $Definition.($_))
            {
                $this.$_ = $Definition.$_
            }
        }
    }

    hidden [void] _setProperties([PSCustomObject] $Definition)
    {
        $this.psobject.properties.Where{$_.IsSettable -and $_.Name -in $Definition.psobject.properties.name}.Name.Foreach{
            if ($null -ne $Definition.($_))
            {
                $this.$_ = $Definition.$_
            }
        }
    }

    [string] ToJSON()
    {
        return ($this | ConvertTo-Yaml -Options JsonCompatible)
    }

    [string] ToYaml()
    {
        return ($this | ConvertTo-Yaml -Options EmitDefaults)
    }

    [string] ToString()
    {
        return $this.ToYaml()
    }
}
