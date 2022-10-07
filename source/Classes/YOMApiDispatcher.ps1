using namespace System.Collections
using namespace System.Collections.Specialized

class YOMApiDispatcher
{
    [string] $ApiVersion
    [string] $Kind
    [string] $Spec
    [OrderedDictionary] $Metadata = [ordered]@{}

    YOMApiDispatcher()
    {
        # empty ctor
    }

    # Constructor currently not used, static method preferred
    YOMApiDispatcher([OrderedDictionary] $ApiDefinition)
    {
        $this.ApiVersion = $ApiDefinition.ApiVersion
        $this.Kind = $ApiDefinition.Kind
        $this.Spec = $ApiDefinition.Spec

        # Everything not ApiVersion/Kind/Spec is considered metadata
        $ApiDefinition.keys.Where{$_ -notin @('ApiVersion','Kind','Spec') }.foreach{
            $this.Metadata.Add($_, $ApiDefinition[$_])
        }
    }

    static [bool] IsDefinition([Object] $OrderedDictionary)
    {
        if ($OrderedDictionary -is [OrderedDictionary] -and $OrderedDictionary.Contains('kind'))
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
        $Action = ''

        if ($Definition.Kind -match '\\')
        {
            $moduleName, $Action = $Definition.Kind.Split('\', 2)
            Write-Debug -Message "Module is '$moduleName'"
            if ($Action -match '\-')
            {
                $moduleString = "Import-Module $moduleName"
            }
            else
            {
                $moduleString = "using module $moduleName"
            }
        }
        else
        {
            $Action = $Definition.Kind
        }

        if ($Action -match '\-')
        {
            # Function
            $functionName = $Action
            Write-Debug -Message "Calling funcion $functionName"
            $returnCode = "`$params = `$Args[0]`r`n ,($functionName @params)"
        }
        elseif ($Action -match '::')
        {
            # Static Method [class]::Method($spec)
            $className, $StaticMethod = $Action.Split('::', 2)
            $StaticMethod = $StaticMethod.Trim('\(\):')
            Write-Debug -Message "Calling static method '[$className]::$StaticMethod(`$spec)'"
            $returnCode = "return [$className]::$StaticMethod(`$args[0])"
        }
        else
        {
            # [Class]::New()
            $className = $Action
            Write-Debug -Message "Creating new [$className]"
            $returnCode = "return [$className]::new(`$args[0])"
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
