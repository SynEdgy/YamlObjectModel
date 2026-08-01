using namespace System.Collections
using namespace System.Collections.Specialized

class YOMApiDispatcher
{
    [string] $ApiVersion
    [string] $Kind
    [string] $Spec
    [OrderedDictionary] $Metadata = [ordered]@{}

    static [bool] IsDefinition([object] $Object) # Testing any object whether it's a definition
    {
        if ($Object -is [IDictionary] -and $Object.Contains('kind'))
        {
            return $true
        }
        else
        {
            return $false
        }
    }

    static [Object] DispatchSpec([string] $DefaultType, [IDictionary] $Definition)
    {
        if ($Definition.Contains('kind'))
        {
            Write-Debug 'Definition defines kind, dispatching.'
            return [YOMApiDispatcher]::DispatchSpec($Definition)
        }
        elseif (
            $Definition.Contains('spec') -and
            ($Definition.Contains('apiVersion') -or $Definition.Contains('metadata'))
        )
        {
            Write-Debug "Dispatching typed short envelope as $DefaultType."
            $typedDefinition = [ordered]@{
                apiVersion = if ($Definition.Contains('apiVersion'))
                {
                    $Definition['apiVersion']
                }
                else
                {
                    ''
                }
                kind = $DefaultType
                metadata = if ($Definition.Contains('metadata'))
                {
                    $Definition['metadata']
                }
                else
                {
                    [ordered]@{}
                }
                spec = $Definition['spec']
            }

            return [YOMApiDispatcher]::DispatchSpec($typedDefinition)
        }
        else
        {
            Write-Debug "Dispatching spec as $DefaultType."
            return [YOMApiDispatcher]::DispatchSpec(
                [ordered]@{
                    kind = $DefaultType
                    spec = $Definition
                }
            )
        }
    }

    static [Object] DispatchSpec([IDictionary] $Definition)
    {
        $moduleString = ''
        $returnCode = ''
        $action = ''
        $moduleLoaded = $null

        if (-not [YOMApiDispatcher]::IsDefinition($Definition))
        {
            throw 'The Definition does not infer the object type to create from those properties. Please define it under the ''kind'' key.'
        }
        elseif (-not $Definition.Contains('spec') -or $Definition['spec'] -isnot [IDictionary])
        {
            throw 'The Definition must contain a dictionary under the ''spec'' key.'
        }
        elseif ($Definition.Kind -match '\\')
        {
            $moduleName, $action = $Definition.Kind.Split('\', 2)
            $moduleLoaded = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
            if ($null -ne $moduleLoaded)
            {
                $moduleString = ('$m = Get-Module -Name ''{0}'' -ErrorAction ''Stop''{1}' -f $moduleName,"`r`n")
            }
            elseif ($action -match '\-')
            {
                $moduleString = "Import-Module $moduleName"
            }
            else
            {
                $moduleString = "using module $moduleName"
            }

            Write-Debug -Message ('Module import: {0}' -f $moduleString)
        }
        else
        {
            $action = $Definition.Kind
        }

        if ($action -match '\-')
        {
            # Function
            $functionName = $action
            Write-Debug -Message "Calling funcion $functionName"
            $returnCode = "`$params = `$Args[0]`r`n ,($functionName @params)"
        }
        elseif ($action -match '::')
        {
            # Static Method [class]::Method($spec)
            $className, $StaticMethod = $action.Split('::', 2)
            $StaticMethod = $StaticMethod.Trim('\(\):')
            $className = $className.Trim('\[\]')
            Write-Debug -Message "Calling static method '[$className]::$StaticMethod(`$spec)'"
            if ($null -ne $moduleLoaded)
            {
                $returnCode = "return (&`$m {return [$className]::$StaticMethod(`$args[0])} `$args[0])"
            }
            else
            {
                $returnCode = "return [$className]::$StaticMethod(`$args[0])"
            }
        }
        else
        {
            # [Class]::New()
            $className = $action
            Write-Debug -Message ('Creating new [{0}]' -f $className)
            if ($null -ne $moduleLoaded)
            {
                $returnCode = "return (&`$m {[$className]::new(`$args[0])} `$args[0])"
            }
            else
            {
                $returnCode = "return [$className]::new(`$args[0])"
            }
        }

        $specObject = $Definition.spec
        $script = "$moduleString`r`n$returnCode"
        Write-Debug -Message "ScriptBlock = {`r`n$script`r`n}"
        $createdObject = [scriptblock]::Create($script).Invoke((,$specObject))[0]
        if ($createdObject.PSobject.Properties.Name -contains 'kind')
        {
            $createdObject.Kind = $Definition.Kind
        }

        if ($createdObject.PSobject.Properties.Name -contains 'ApiVersion')
        {
            $createdObject.ApiVersion = if ($Definition.Contains('apiVersion'))
            {
                [string] $Definition['apiVersion']
            }
            else
            {
                ''
            }
        }

        if ($createdObject.PSobject.Properties.Name -contains 'Metadata')
        {
            $createdObject.Metadata = [ordered]@{}
            if ($Definition.Contains('metadata') -and $null -ne $Definition['metadata'])
            {
                if ($Definition['metadata'] -isnot [IDictionary])
                {
                    throw 'The Definition metadata must be a dictionary.'
                }

                foreach ($metadataKey in $Definition['metadata'].Keys)
                {
                    $createdObject.Metadata[$metadataKey] = $Definition['metadata'][$metadataKey]
                }
            }
        }

        return $createdObject
    }
}
