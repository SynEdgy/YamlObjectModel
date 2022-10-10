class YOMOther : YOMSaveableBase
{
    [YOMTest] $Test

    YOMOther()
    {
        # Default ctor
    }

    YOMOther([System.Collections.IDictionary]$RawSpec)
    {
        $this.ResolveSpec($RawSpec)
    }

    YOMOther([string] $Path)
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
}
