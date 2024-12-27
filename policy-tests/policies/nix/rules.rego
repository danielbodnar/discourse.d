# policies/nix/rules.rego
package nix.rules

# Flake validation
deny[msg] {
    input.kind == "Flake"
    not input.inputs

    msg = "flake must specify inputs"
}

# Development shell validation
deny[msg] {
    input.kind == "DevShell"
    not input.packages

    msg = "development shell must specify packages"
}

# System configuration validation
deny[msg] {
    input.kind == "NixOS"
    not input.system.stateVersion

    msg = "NixOS configuration must specify system.stateVersion"
}
