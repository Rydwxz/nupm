use std assert

use ../nupm
use ../nupm/test.nu with-test-env

const TEST_REGISTRY_PATH = ([tests packages registry registry.nuon] | path join)
const TEST_REGISTRY_RECORD = { NUPM_REGISTRIES: { test: $TEST_REGISTRY_PATH }}

# Examples:
#     make sure `$env.NUPM_HOME/scripts/script.nu` exists
#     > assert installed [scripts script.nu]
def "assert installed" [path_tokens: list<string>] {
    assert ($path_tokens | prepend $env.NUPM_HOME | path join | path exists)
}

def check-file-content [content: string] {
    let file_str = open ($env.NUPM_HOME | path join scripts spam_script.nu)
    assert ($file_str | str contains $content)
}


export def install-script [] {
    with-test-env {
        nupm install --path tests/packages/spam_script

        assert installed [scripts spam_script.nu]
        assert installed [scripts spam_bar.nu]
    } $TEST_REGISTRY_RECORD
}

export def install-module [] {
    with-test-env {
        nupm install --path tests/packages/spam_module

        assert installed [scripts script.nu]
        assert installed [modules spam_module]
        assert installed [modules spam_module mod.nu]
    } $TEST_REGISTRY_RECORD
}

export def install-custom [] {
    with-test-env {
        nupm install --path tests/packages/spam_custom

        assert installed [plugins nu_plugin_test]
    } $TEST_REGISTRY_RECORD
}

export def install-from-local-registry [] {
    with-test-env {
        let test_reg = $env.NUPM_REGISTRIES.test
        $env.NUPM_REGISTRIES = {}
        nupm install --registry $test_reg spam_script
        check-file-content 0.2.0
    } $TEST_REGISTRY_RECORD

    with-test-env {
        nupm install --registry test spam_script
        check-file-content 0.2.0
    } $TEST_REGISTRY_RECORD

    with-test-env {
        nupm install spam_script
        check-file-content 0.2.0
    } $TEST_REGISTRY_RECORD
}

export def install-with-version [] {
    with-test-env {
        nupm install spam_script -v 0.1.0
        check-file-content 0.1.0
    } $TEST_REGISTRY_RECORD
}

export def install-multiple-registries-fail [] {
    with-test-env {
        let test_reg = $env.NUPM_REGISTRIES.test
        $env.NUPM_REGISTRIES.test2 = $test_reg

        let out = try {
            nupm install spam_script
            "wrong value that shouldn't match the assert below"
        } catch {|err|
            $err.msg
        }

        assert ("Multiple registries contain package spam_script" in $out)
    } $TEST_REGISTRY_RECORD
}

export def install-package-not-found [] {
    with-test-env {
        let out = try {
            nupm install invalid-package
            "wrong value that shouldn't match the assert below"
        } catch {|err|
            $err.msg
        }

        assert ("Package invalid-package not found in any registry" in $out)
    } $TEST_REGISTRY_RECORD
}

export def search-registry [] {
    with-test-env {
        assert ((nupm search spam | length) == 4)
    } $TEST_REGISTRY_RECORD
}

export def nupm-status-module [] {
    with-test-env {
        let files = (nupm status tests/packages/spam_module).files
        assert ($files.0 ends-with (
            [tests packages spam_module spam_module mod.nu] | path join))
        assert ($files.1.0 ends-with (
            [tests packages spam_module script.nu] | path join))
    } $TEST_REGISTRY_RECORD
}

export def env-vars-are-set [] {
    $env.NUPM_HOME = null
    $env.NUPM_TEMP = null
    $env.NUPM_CACHE = null
    $env.NUPM_REGISTRIES = null

    use ../nupm/utils/dirs.nu
    use ../nupm

    assert equal $env.NUPM_HOME $dirs.DEFAULT_NUPM_HOME
    assert equal $env.NUPM_TEMP $dirs.DEFAULT_NUPM_TEMP
    assert equal $env.NUPM_CACHE $dirs.DEFAULT_NUPM_CACHE
    assert equal $env.NUPM_REGISTRIES $dirs.DEFAULT_NUPM_REGISTRIES
}

export def generate-local-registry [] {
    with-test-env {
        mkdir ($env.NUPM_TEMP | path join packages registry)

        let reg_file = [tests packages registry registry.nuon] | path join
        let tmp_reg_file = [
            $env.NUPM_TEMP packages registry test_registry.nuon
        ]
        | path join

        touch $tmp_reg_file

        [spam_script spam_script_old spam_custom spam_module] | each {|pkg|
            cd ([tests packages $pkg] | path join)
            nupm publish $tmp_reg_file --local --save --path (".." | path join $pkg)
        }

        let actual = open $tmp_reg_file | to nuon
        let expected = open $reg_file | to nuon

        assert equal $actual $expected
    } $TEST_REGISTRY_RECORD
}
