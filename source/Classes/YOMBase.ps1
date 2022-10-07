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

    YOMBaseObject()
    {
        # empty ctor
    }

    YOMBaseObject([IDictionary]$RawSpec)
    {
        $this.ResolveSpec($RawSpec)
    }

    [void] Read([IParser] $Parser, [Type] $Type, [ObjectDeserializer] $NestedObjectDeserializer)
    {
        # $consumeGenericMethod = [IParser].GetMethod("TryConsume")
        # $closedConsumeGenericMethod = $consumeGenericMethod.MakeGenericMethod([SequenceStart])
        # $closedConsumeGenericMethod.Invoke()

        # while ($Parser.TryConsume<Scalar>(out var $key))
        # {
        #     if ($key.Value == "config_two")
        #     {
        #         var config = deserializer.Deserialize<ConfigTwo>(parser);
        #         Console.WriteLine(config.Random);
        #     }
        #     else
        #     {
        #         parser.SkipThisAndNestedEvents();
        #         Console.WriteLine($"Skipped {key.Value}");
        #     }
        # }
        # $scalar = $Parser.Allow()
        # if ($null -ne $scalar)
        # {
        #     $this.Test = $scalar.Value
        #     $this.Prod = $scalar.Value
        # }
        # else
        # {
        #     # var values = (SettingsBase)nestedObjectDeserializer(typeof(SettingsBase));
        #     # this.Test = values.Test;
        #     # this.Prod = values.Prod;
        # }
    }

    [void] Write([IEmitter] $Emitter, [ObjectSerializer] $NestedObjectSerializer)
    {
        $outerObject = [ordered]@{
            kind = $this.GetType().ToString() # Problem here is that we don't know which module it's coming from...
            specs = [ordered]@{}
        }

        $this.PSObject.Properties.Where({
            $_.Name -in $this.GetType().GetProperties().Where{$_.CustomAttributes.AttributeType -ne [YamlDotNet.Serialization.YamlIgnoreAttribute]}.name -and
            $true -eq $_.IsSettable}).Foreach{
            $outerObject.specs.Add($_.Name,$_.Value)
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
        if ($RawSpec -isnot [OrderedDictionary] -and $RawSpec -as [hashtable])
        {
            $RawSpec = ([ordered]@{} + $RawSpec)
        }
        elseif ($RawSpec -is [OrderedDictionary])
        {
            Write-Debug -Message "Rawspec is an Ordered Dictionary. No Conversion needed."
        }
        else
        {
            $this.Spec = [ordered]@{}
            throw "Error trying to build the object defined by:`n $($RawSpec | ConvertTo-Yaml -Options EmitDefaults)"
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
