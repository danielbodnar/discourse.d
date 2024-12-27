# policies/base/main.rego
package main

import data.docker.rules as docker
import data.kubernetes.rules as kubernetes
import data.helm.rules as helm
import data.nix.rules as nix

# Global deny rules
deny[msg] {
    docker.deny[msg]
}

deny[msg] {
    kubernetes.deny[msg]
}

deny[msg] {
    helm.deny[msg]
}

deny[msg] {
    nix.deny[msg]
}

# Common validation functions
is_null(value) {
    value == null
}

is_empty(value) {
    count(value) == 0
}

contains_key(obj, key) {
    obj[key]
}
