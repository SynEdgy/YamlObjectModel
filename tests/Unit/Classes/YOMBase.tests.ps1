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

    It 'should omit unset optional envelope fields' {
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
        $yaml = $YOMBaseInstance.ToYaml() | ConvertFrom-Yaml -Ordered
        $json = $YOMBaseInstance.ToJSON() | ConvertFrom-Json

        @($yaml.Keys) | Should -Be @('kind', 'spec')
        $yaml.kind | Should -Be 'YOMBase'
        $json.kind | Should -Be 'YOMBase'
        $json.PSObject.Properties.Name | Should -Not -Contain 'apiVersion'
        $json.PSObject.Properties.Name | Should -Not -Contain 'metadata'
    }

    It 'should preserve resource envelope values through construction and serialization' {
        $YOMBaseInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMBase]::new([ordered]@{
                apiVersion = 'yom.synedgy.com/v1alpha1'
                kind = 'YamlObjectModel\YOMBase'
                metadata = [ordered]@{
                    Name = 'round-trip'
                    Labels = [ordered]@{
                        purpose = 'unit-test'
                    }
                }
                spec = [ordered]@{}
            })
        }

        $serialized = $YOMBaseInstance.ToYaml() | ConvertFrom-Yaml -Ordered

        $serialized.apiVersion | Should -Be 'yom.synedgy.com/v1alpha1'
        $serialized.kind | Should -Be 'YamlObjectModel\YOMBase'
        $serialized.metadata.Name | Should -Be 'round-trip'
        $serialized.metadata.Labels.purpose | Should -Be 'unit-test'
    }

    It 'should continue accepting legacy kind and spec construction' {
        $YOMBaseInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMBase]::new([ordered]@{
                kind = 'YOMBase'
                spec = [ordered]@{}
            })
        }

        $YOMBaseInstance.Kind | Should -Be 'YOMBase'
        $YOMBaseInstance.ApiVersion | Should -Be ''
        $YOMBaseInstance.Metadata.Count | Should -Be 0
    }

    It 'should accept null metadata as empty metadata' {
        $YOMBaseInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMBase]::new([ordered]@{
                kind = 'YOMBase'
                metadata = $null
                spec = [ordered]@{}
            })
        }

        $YOMBaseInstance.Metadata.Count | Should -Be 0
    }

    It 'should reject non-dictionary metadata' {
        {
            InModuleScope @CurrentModule -ScriptBlock {
                [YOMBase]::new([ordered]@{
                    kind = 'YOMBase'
                    metadata = 'invalid'
                    spec = [ordered]@{}
                })
            }
        } | Should -Throw '*metadata must be a dictionary*'
    }

    It 'should reject a resource envelope with a non-dictionary spec' {
        {
            InModuleScope @CurrentModule -ScriptBlock {
                [YOMBase]::new([ordered]@{
                    kind = 'YOMBase'
                    spec = 'invalid'
                })
            }
        } | Should -Throw '*spec must be a dictionary*'
    }

    It 'should reject a null raw spec' {
        {
            InModuleScope @CurrentModule -ScriptBlock {
                [YOMBase]::new([System.Collections.IDictionary] $null)
            }
        } | Should -Throw '*RawSpec*'
    }

    It 'should omit metadata when it is explicitly cleared before serialization' {
        $YOMBaseInstance = InModuleScope @CurrentModule -ScriptBlock {
            $instance = [YOMBase]::new()
            $instance.Metadata = $null
            $instance
        }

        $serialized = $YOMBaseInstance.ToYaml() | ConvertFrom-Yaml -Ordered
        $serialized.Contains('metadata') | Should -BeFalse
    }

    It 'should construct directly from a typed short envelope' {
        $YOMBaseInstance = InModuleScope @CurrentModule -ScriptBlock {
            [YOMBase]::new([ordered]@{
                apiVersion = 'yom.synedgy.com/v1alpha1'
                metadata = [ordered]@{
                    Name = 'direct-short'
                }
                spec = [ordered]@{}
            })
        }

        $YOMBaseInstance.ApiVersion | Should -Be 'yom.synedgy.com/v1alpha1'
        $YOMBaseInstance.Metadata.Name | Should -Be 'direct-short'
    }

    It 'should reject non-dictionary metadata in a typed short envelope' {
        {
            InModuleScope @CurrentModule -ScriptBlock {
                [YOMBase]::new([ordered]@{
                    metadata = 'invalid'
                    spec = [ordered]@{}
                })
            }
        } | Should -Throw '*metadata must be a dictionary*'
    }

    It 'should reject non-dictionary spec in a typed short envelope' {
        {
            InModuleScope @CurrentModule -ScriptBlock {
                [YOMBase]::new([ordered]@{
                    apiVersion = 'yom.synedgy.com/v1alpha1'
                    spec = 'invalid'
                })
            }
        } | Should -Throw '*spec must be a dictionary*'
    }
}
