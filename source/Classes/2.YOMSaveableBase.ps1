using namespace YamlDotNet.Core
using namespace YamlDotNet.Serialization

class YOMSaveableBase : YOMBase
{
    # SavedAtPath
    [YamlIgnoreAttribute()]
    [string] $SavedAtPath

    # Constructor for Empty object
    YOMSaveableBase()
    {
        # Default Ctor
    }

    # Constructor For IDictionary (Hashtable, OrderedDictionary...)
    YOMSaveableBase([IDictionary]$Definition)
    {
        $this.ResolveSpec($Definition)
    }

    YOMSaveableBase([string] $Path)
    {
        $FilePath = Get-YOMAbsolutePath -Path $Path
        Write-Debug -Message "Loading settings from Path '$FilePath'."
        if (-not (Test-Path -Path $FilePath))
        {
            throw ('Error loading file ''{0}''' -f $FilePath)
        }

        $this.LoadFromFile($FilePath)
        $this.SavedAtPath = $FilePath
    }

    [void] LoadFromFile([string] $Path)
    {
        Write-Debug -Message "Loading Properties from '$Path'."
        $FilePath = Get-YOMAbsolutePath -Path $Path
        $Definition = ConvertFrom-Yaml -Ordered -Yaml (Get-Content -Raw -Path $FilePath)
        $this.ResolveSpec($Definition)
    }

    [void] Reload()
    {
        if ([string]::IsNullOrEmpty($this.SavedAtPath))
        {
            throw 'Cannot Reload when Definition file is not set. Try using the method .LoadFromFile([string] $Path) instead.'
            return
        }

        $this.LoadFromFile($this.SavedAtPath)
    }

    [void] Save()
    {
        # Save the Settings to file
        if ([string]::IsNullOrEmpty($this.SavedAtPath))
        {
            throw 'No file path is configured on the object to Save to. Please use the .SaveTo([string]$Path) method instead.'
        }
        else
        {
            $this.SaveTo($this.SavedAtPath)
        }
    }

    [void] SaveTo([string] $Path)
    {
        Write-Debug -Message "Saving the Definition to '$Path'."
        # Save the Configuration to a path (override if exists)
        $this.ToYaml() | Set-Content -Path $Path -Force
        $this.SavedAtPath = $Path
    }
}
