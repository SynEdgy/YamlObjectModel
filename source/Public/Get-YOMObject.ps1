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
        if ($PSCmdlet.ParameterSetName -eq 'ByPath')
        {
            $Definition = foreach ($pathItem in $Path)
            {
                $files = if (Test-Path -Path $pathItem -PathType Container)
                {
                    #TODO: Handle new defaults on subdirectories if defined
                    (Get-ChildItem -Path $pathItem -File -Include *.yml -Recurse).FullName
                }
                else
                {
                    Get-YOMAbsolutePath -Path $pathItem
                }

                $files.foreach({
                    $fileItem = $_
                    #TODO: Each file is a container representing objects
                    (Get-Content -Raw -Path $_ |
                      ConvertFrom-Yaml -AllDocuments -Ordered).Foreach{
                        if ([string]::IsNullOrEmpty($_.kind))
                        {
                            $_['SavedAtPath'] = $fileItem
                        }
                        else
                        {
                            $_['spec']['SavedAtPath'] = $fileItem
                        }

                        $_ #returning definition dans $Definition
                      }
                })
            }
        }
    }

    process {
        foreach ($objectDefinition in $Definition)
        {
            if ($DefaultType)
            {
                Write-Debug -Message "Trying to build the object [DefaultType: $DefaultType].`r`n$($objectDefinition)"
                [YOMApiDispatcher]::DispatchSpec($DefaultType, $objectDefinition)
            }
            else
            {
                Write-Debug -Message "Trying to build the object:`r`n $($objectDefinition | ConvertTo-Yaml -Options EmitDefaults)"
                [YOMApiDispatcher]::DispatchSpec($objectDefinition)
            }
        }
    }
}
