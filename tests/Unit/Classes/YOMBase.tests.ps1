param ()

BeforeAll {
    $CurrentModule = @{
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

Describe 'Validating class [YOMBase]' {

    BeforeEach {
        $YOMBase = InModuleScope @CurrentModule -ScriptBlock {
            [YOMBase]::new()
        }
    }

    It 'should have the ToString() method' {
        $YOMBase.ToString | Should -not -BeNullOrEmpty
    }

    It 'should have the ToYaml() method' {
        $YOMBase.ToString | Should -not -BeNullOrEmpty
    }

    It 'should have the ToJson() method' {
        $YOMBase.ToString | Should -not -BeNullOrEmpty
    }

    It 'should correctly instantiate the YOMBase class by casting a hashtable' {
        $YOMBaseInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMBase]@{
                test = 'abc'
            }
        }

        $YOMBaseInstance | Should -Not -BeNullOrEmpty
    }

    It 'should correctly instantiate the YOMBase class by casting kind/spec hash' {
        $YOMBaseInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMBase]@{
                kind = 'YOMBase'
                spec = @{
                    test = 'abc'
                }
            }
        }

        $YOMBaseInstance | Should -Not -BeNullOrEmpty
    }

    It 'should correctly instantiate the YOMBase class by kind/spec' {
        $YOMBaseInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMBase]::new(@{
                kind = 'YOMBase'
                spec = @{
                    test = 'abc'
                }
            })
        }

        $YOMBaseInstance | Should -Not -BeNullOrEmpty
    }

    It 'should serialize the class without undefined properties but kind|spec' {
        $YOMBaseInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMBase]@{
                test = 'abc'
                somethingElse = 'foo'
                keepIgnoringme = 123
            }
        }

        $YOMBaseInstance | Should -Not -BeNullOrEmpty
        $YOMBaseInstance.test | Should -BeNullOrEmpty
        $YOMBaseInstance.somethingElse | Should -BeNullOrEmpty
        $YOMBaseInstance.ToYaml() | Should -Match '^kind: YOMBase'
        $YOMBaseInstance.ToJSON() | Should -Match '^{\s*\"kind":\s*\"YOMBase\"'
    }
}
