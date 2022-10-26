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
        if (-not $Definition.Contains('kind'))
        {
            Write-Debug "Dispatching spec as $DefaultType."
            return [YOMApiDispatcher]::DispatchSpec(
                [ordered]@{
                    kind = $DefaultType
                    spec = $Definition
                }
            )
        }
        else
        {
            Write-Debug "Definition defines kind, dispatching."
            return [YOMApiDispatcher]::DispatchSpec($Definition)
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
                $returnCode = "return (&`$m {return [$className]::$StaticMethod(`$args[0])})"
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
                $returnCode = "return (&`$m {[$className]::new(`$args[0])})"
            }
            else
            {
                $returnCode = "return [$className]::new(`$args[0])"
            }
        }

        $specObject = $Definition.spec
        $script = "$moduleString`r`n$returnCode"
        Write-Debug -Message "ScriptBlock = {`r`n$script`r`n}"
        $createdObject = [scriptblock]::Create($script).Invoke($specObject)[0]
        if ($createdObject.PSobject.Properties.Name -contains 'kind')
        {
            #TODO: Make sure the file metadata is also available here
            $createdObject.Kind = $Definition.Kind
        }

        return $createdObject
    }
}
