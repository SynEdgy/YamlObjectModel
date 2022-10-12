BeforeAll {
    $CurrentModule = @{
        ModuleName = 'YamlObjectModel'
    }

    Import-Module -Name 'YamlObjectModel' -Force -ErrorAction Stop
    $YOMTestClass = Get-Content -Raw -Path "$PSScriptRoot/../assets/3.YOMTest.ps1"
    $YOMOtherClass = Get-Content -Raw -Path "$PSScriptRoot/../assets/4.YOMOther.ps1"

    $sb = @"
    using module $PSScriptRoot/../../../output/module/YamlObjectModel
    $YOMTestClass
    $YOMOtherClass
"@
}

Describe 'Testing the [YOMSaveAble] class' {
    context 'Loading from file' {
        It 'Creates an instance of object by path' {
            $obj = InModuleScope @CurrentModule -ScriptBlock {
                [YOMSaveableBase]"$PSScriptRoot/../assets/OtherObj.yml"
            }

            $obj | Should -not -BeNullOrEmpty
            $obj.SavedAtPath | Should -Exist
        }

        It 'Should throw when no file exists' {
            {
                InModuleScope @CurrentModule -ScriptBlock {
                    [YOMSaveableBase]"$testdrive/donotexist.yml"
                }
            } | Should -Throw
        }

        It 'Should reload an object when its file was changed' {
                $sb = $sb,@"
        `$obj = [YOMOther]@{
            test = ([YOMTest]@{
                stuff = 'ReplaceME'
            })
        }

        `$obj.SaveTo('$testdrive/obj.yml')
        Set-Content -Path '$testdrive/obj.yml' -Value ((Get-Content -Raw -Path '$testdrive/obj.yml') -replace 'ReplaceME','Something else')
        `$obj.Reload()
        `$obj
"@ -join "`r`n"
            $obj = InModuleScope @CurrentModule -ScriptBlock ([scriptblock]::create($sb))
            $obj.test.stuff | Should -match 'Something else'
        }
    }

    context 'Saving to a file' {
        It 'Should save the serialized Yaml to a file' {
            $sb = $sb,@"
    `$obj = [YOMOther]@{
        test = ([YOMTest]@{
            stuff = 'trying to save to a file'
        })
    }

    `$obj.SaveTo('$testdrive/obj.yml')
    '$testdrive/obj.yml'
"@ -join "`r`n"
            $test = InModuleScope @CurrentModule -ScriptBlock ([scriptblock]::create($sb))
            $test | Should -exist
            $obj = (Get-Content -Raw -Path $test | ConvertFrom-Yaml)
            $obj | Should -Not -BeNullOrEmpty
            $obj.spec.Test.spec.Stuff | Should -be 'trying to save to a file'
        }
    }

    It 'Should be able to re-save to a file after a change since SavedPathPath is set' {
        $sb = $sb,
        @"
        `$obj = [YOMOther]@{
            test = ([YOMTest]@{
                stuff = 'trying to save to a file'
            })
        }

        `$obj.SaveTo('$testdrive/obj2.yml')
        `$obj.test.stuff = 'Another test'
        `$obj.Save()
        `$obj
"@ -join "`r`n"
        $obj = InModuleScope @CurrentModule -ScriptBlock ([scriptblock]::create($sb))
        $obj | Should -not -BeNullOrEmpty
        $obj.SavedAtPath | Should -Exist
        $obj.test.Stuff | Should -be 'Another test'
        Get-Content -Raw -path $obj.SavedAtPath | Should -match 'Another test'
    }
}
