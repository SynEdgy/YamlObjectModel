function Get-YOMObject
{
    [CmdletBinding(DefaultParameterSetName= 'ByPath')]
    param (
        [Parameter(ParameterSetName = 'ByPath', Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path,

        [Parameter(ParameterSetName = 'ByDictionary', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]
        $Definition,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DefaultType
    )

    begin
    {
        $dispatchDefinition = {
            param
            (
                [Parameter()]
                [IDictionary]
                $ObjectDefinition,

                [Parameter()]
                [string]
                $SourcePath
            )

            $createdObject = if ($DefaultType)
            {
                Write-Debug -Message "Trying to build the object [DefaultType: $DefaultType].`r`n$($ObjectDefinition)"
                [YOMApiDispatcher]::DispatchSpec($DefaultType, $ObjectDefinition)
            }
            else
            {
                Write-Debug -Message "Trying to build the object:`r`n $($ObjectDefinition | ConvertTo-Yaml -Options EmitDefaults)"
                [YOMApiDispatcher]::DispatchSpec($ObjectDefinition)
            }

            if (
                -not [string]::IsNullOrEmpty($SourcePath) -and
                $createdObject.PSObject.Properties.Name -contains 'SavedAtPath'
            )
            {
                $createdObject.SavedAtPath = $SourcePath
            }

            return $createdObject
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'ByPath')
        {
            foreach ($pathItem in $Path)
            {
                $files = if (Test-Path -Path $pathItem -PathType Container)
                {
                    (Get-ChildItem -Path $pathItem -File -Filter '*.yml' -Recurse).FullName
                }
                else
                {
                    Get-YOMAbsolutePath -Path $pathItem
                }

                foreach ($fileItem in $files)
                {
                    $objectDefinitions = Get-Content -Raw -Path $fileItem |
                        ConvertFrom-Yaml -AllDocuments -Ordered

                    foreach ($objectDefinition in $objectDefinitions)
                    {
                        & $dispatchDefinition $objectDefinition $fileItem
                    }
                }
            }
        }
        else
        {
            foreach ($objectDefinition in $Definition)
            {
                & $dispatchDefinition $objectDefinition ''
            }
        }
    }
}
