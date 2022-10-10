BeforeAll {
    Import-Module -Name YamlObjectModel

    $module = @{
        ModuleName = 'YamlObjectModel'
    }
}

Describe 'Testing private function Get-YOMAbsolutePath' {
    It 'Should have the function private' {
        (Get-Command -Module 'YamlObjectModel').Name | Should -not -Contain 'Get-YOMAbsolutePath'
        $allInternalCommands = InModuleScope @module -ScriptBlock {
            (Get-Command -Module 'YamlObjectModel').Name
        }
        $allInternalCommands | Should -Contain 'Get-YOMAbsolutePath'
    }

    It 'Should resolve an the absolute path to the test drive' {
        $path = InModuleScope @module -ScriptBlock {
            Get-YOMAbsolutePath -Path '.' -RelativeTo $testdrive
        }

        $path | Should -not -BeNullOrEmpty
        ($path | Convert-Path) | Should -Be ($testdrive | Convert-Path)
    }

    It 'Should resolve an the absolute path of a test subfolder' {
        $path = InModuleScope @module -ScriptBlock {
            Get-YOMAbsolutePath -Path 'subfolder' -RelativeTo $testdrive
        }

        $path | Should -be (Join-Path -Path $testdrive -ChildPath 'subfolder')
    }

    It 'Should resolve an the absolute path based on current pwd' {
        $path = InModuleScope @module -ScriptBlock {
            Push-Location -Path $testdrive
            Get-YOMAbsolutePath -Path 'subfolder'
            Pop-Location
        }

        $path | Should -be (Join-Path -Path $testdrive -ChildPath 'subfolder')
    }

    It 'Should resolve an the absolute path based on current pwd at drive root' {
        $path = InModuleScope @module -ScriptBlock {
            Push-Location -Path 'TestDrive:\'
            Get-YOMAbsolutePath -Path 'subfolder'
            Pop-Location
        }

        $path | Should -be (Join-Path -Path $testdrive -ChildPath 'subfolder')
    }
}
