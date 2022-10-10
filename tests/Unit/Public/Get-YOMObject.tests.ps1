BeforeAll {
    $module = @{
        ModuleName = 'YamlObjectModel'
    }

    Import-Module -Name YamlObjectModel -Force -ErrorAction Stop
    $YOMTestClass = Get-Content -Raw -Path "$PSScriptRoot/../assets/3.YOMTest.ps1"
    $YOMOtherClass = Get-Content -Raw -Path "$PSScriptRoot/../assets/4.YOMOther.ps1"

    $sb = @"
    using module $PSScriptRoot/../../../output/module/YamlObjectModel
    $YOMTestClass
    $YOMOtherClass
"@
}

Describe 'Get-YOMObject' {

    It 'should load the correct object from obj.yml asset' {
        $sb = $sb,"Get-YOMObject -Path '$PSScriptRoot/../assets/obj.yml' -ErrorAction 'stop'" -join "`r`n"
        $obj = InModuleScope @module -ScriptBlock ([scriptblock]::create($sb))
        $obj | Should -Not -BeNullOrEmpty
        $obj.Save | Should -not -BeNullOrEmpty
        $obj.test.stuff | Should -Be 'testing something magic'
    }

    It 'should load all objects from folder asset' {

        $sb = $sb,"Get-YOMObject -Path '$PSScriptRoot/../assets/multi' -ErrorAction 'stop'" -join "`r`n"
        $obj = InModuleScope @module -ScriptBlock ([scriptblock]::create($sb))
        $obj | Should -Not -BeNullOrEmpty
        $obj.count | Should -be 2
    }

    It 'should load all objects from folder asset when DefaultType is specified' {

        $sb = $sb,"Get-YOMObject -Path '$PSScriptRoot/../assets/multiNoKind' -DefaultType 'YOMTest' -ErrorAction 'stop'" -join "`r`n"
        $obj = InModuleScope @module -ScriptBlock ([scriptblock]::create($sb))
        $obj | Should -Not -BeNullOrEmpty
        $obj.count | Should -be 2
    }

    It 'Should create an object when given properties and default type' {
        $sb = $sb,@"
    `$props = @{
        stuff = 'Something else'
    }
    Get-YOMObject -Definition `$props -DefaultType 'YOMTest' -ErrorAction 'stop'
"@ -join "`r`n"
        $obj = InModuleScope @module -ScriptBlock ([scriptblock]::create($sb))
        $obj.stuff | Should -be 'Something else'
    }

    It 'Should create an object when given specs and kind' {
        $sb = $sb,@"
    `$def = @{
        kind = 'YOMTest'
        spec = @{
            stuff = 'Something special'
        }
    }
    Get-YOMObject -Definition `$def -ErrorAction 'stop'
"@ -join "`r`n"
        $obj = InModuleScope @module -ScriptBlock ([scriptblock]::create($sb))
        $obj.stuff | Should -be 'Something special'
    }
}
