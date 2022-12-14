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
        $outerObject = [ordered]@{
            kind = $this.GetType().ToString() # Problem here is that we don't know which module it's coming from...
            spec = [ordered]@{}
        }

        $this.PSObject.Properties.Where({
            $_.Name -in $this.GetType().GetProperties().Where{$_.CustomAttributes.AttributeType -ne [YamlDotNet.Serialization.YamlIgnoreAttribute]}.name -and
            $true -eq $_.IsSettable}).Foreach{
            $outerObject.spec.Add($_.Name,$_.Value)
        }

        $NestedObjectSerializer.Invoke($outerObject)
    }

    hidden [void] ResolveSpec([string] $kind, [IDictionary] $RawSpec)
    {
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
