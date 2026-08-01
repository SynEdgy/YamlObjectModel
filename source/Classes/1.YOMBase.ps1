using namespace YamlDotNet.Core
using namespace YamlDotNet.Serialization
using namespace YamlDotNet.Core.Events
using namespace System.Collections
using namespace System.Collections.Generic
using namespace System.Collections.Specialized

class YOMBase : IYamlConvertible
{
    [YamlIgnoreAttribute()]
    [string] $ApiVersion = ''
    [YamlIgnoreAttribute()]
    [string] $Kind = ''
    [YamlIgnoreAttribute()]
    [OrderedDictionary] $Metadata = [ordered]@{}
    [YamlIgnoreAttribute()]
    hidden [OrderedDictionary] $Spec = [ordered]@{}

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
        $outerObject = [ordered]@{}

        if (-not [string]::IsNullOrEmpty($this.ApiVersion))
        {
            $outerObject['apiVersion'] = $this.ApiVersion
        }

        $outerObject['kind'] = if ([string]::IsNullOrEmpty($this.Kind))
        {
            $this.GetType().ToString()
        }
        else
        {
            $this.Kind
        }

        if ($null -ne $this.Metadata -and $this.Metadata.Count -gt 0)
        {
            $outerObject['metadata'] = $this.Metadata
        }

        $outerObject['spec'] = [ordered]@{}

        $this.PSObject.Properties.Where({
            $_.Name -in $this.GetType().GetProperties().Where{
                $_.CustomAttributes.AttributeType -ne [YamlDotNet.Serialization.YamlIgnoreAttribute]
            }.name -and
            $true -eq $_.IsSettable}).Foreach{
            $outerObject.spec.Add($_.Name,$_.Value)
        }

        $NestedObjectSerializer.Invoke($outerObject)
    }

    hidden [void] ResolveSpec([string] $kind, [IDictionary] $RawSpec)
    {
        $this.Kind = $kind
        $this.ResolveSpecProperties($RawSpec)
    }

    hidden [void] ResolveSpec([IDictionary] $RawSpec)
    {
        if ($null -eq $RawSpec)
        {
            throw [System.ArgumentNullException]::new('RawSpec')
        }

        if ($RawSpec.Contains('kind'))
        {
            $this.Kind = [string] $RawSpec['kind']

            if ($RawSpec.Contains('apiVersion'))
            {
                $this.ApiVersion = [string] $RawSpec['apiVersion']
            }

            if ($RawSpec.Contains('metadata'))
            {
                $this.Metadata = [ordered]@{}
                if ($null -ne $RawSpec['metadata'])
                {
                    if ($RawSpec['metadata'] -isnot [IDictionary])
                    {
                        throw [System.ArgumentException]::new('metadata must be a dictionary.')
                    }

                    foreach ($metadataKey in $RawSpec['metadata'].Keys)
                    {
                        $this.Metadata[$metadataKey] = $RawSpec['metadata'][$metadataKey]
                    }
                }
            }

            if (-not $RawSpec.Contains('spec') -or $RawSpec['spec'] -isnot [IDictionary])
            {
                throw [System.ArgumentException]::new('spec must be a dictionary.')
            }

            $this.ResolveSpecProperties($RawSpec['spec'])
        }
        elseif (
            $RawSpec.Contains('spec') -and
            ($RawSpec.Contains('apiVersion') -or $RawSpec.Contains('metadata'))
        )
        {
            if ($RawSpec.Contains('apiVersion'))
            {
                $this.ApiVersion = [string] $RawSpec['apiVersion']
            }

            if ($RawSpec.Contains('metadata'))
            {
                $this.Metadata = [ordered]@{}
                if ($null -ne $RawSpec['metadata'])
                {
                    if ($RawSpec['metadata'] -isnot [IDictionary])
                    {
                        throw [System.ArgumentException]::new('metadata must be a dictionary.')
                    }

                    foreach ($metadataKey in $RawSpec['metadata'].Keys)
                    {
                        $this.Metadata[$metadataKey] = $RawSpec['metadata'][$metadataKey]
                    }
                }
            }

            if ($RawSpec['spec'] -isnot [IDictionary])
            {
                throw [System.ArgumentException]::new('spec must be a dictionary.')
            }

            $this.ResolveSpecProperties($RawSpec['spec'])
        }
        else
        {
            $this.ResolveSpecProperties($RawSpec)
        }
    }

    hidden [void] ResolveSpecProperties([IDictionary] $RawSpec)
    {
        $this.Spec = [ordered]@{}

        foreach ($keyInSpec in $RawSpec.Keys)
        {
            Write-Debug -Message "Testing value of [$keyInSpec] for object definition..."
            $ValueForSpec = if ([YOMApiDispatcher]::IsDefinition($RawSpec.($keyInSpec)))
            {
                Write-Debug -Message 'Resolving value as an object.'
                [YOMApiDispatcher]::DispatchSpec($RawSpec.($keyInSpec))
            }
            else
            {
                Write-Debug -Message "The Value is --->$($RawSpec.($keyInSpec))"
                $RawSpec.($keyInSpec)
            }

            $this.Spec.Add($keyInSpec,$ValueForSpec)
            if ($this.PSObject.Properties.Item($keyInSpec).IsSettable)
            {
                $this.($keyInSpec) = $RawSpec.($keyInSpec)
            }
        }
    }

    [string] ToJSON()
    {
        return ($this | ConvertTo-Yaml -Options EmitDefaults,JsonCompatible)
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
