# policies/helm/rules.rego
package helm.rules

# Values validation
deny[msg] {
    input.kind == "HelmValues"
    not input.resources.limits

    msg = "helm values must specify resource limits"
}

# Ingress validation
deny[msg] {
    input.kind == "HelmValues"
    input.ingress.enabled
    not input.ingress.tls

    msg = "ingress must have TLS configured when enabled"
}

# Storage validation
deny[msg] {
    input.kind == "HelmValues"
    input.persistence.enabled
    not input.persistence.size

    msg = "persistence configuration must specify size"
}

# Dependencies validation
deny[msg] {
    input.kind == "Chart"
    not valid_dependencies

    msg = "chart dependencies must specify version constraints"
}

valid_dependencies {
    dep := input.dependencies[_]
    dep.version
}
