# policies/kubernetes/rules.rego
package kubernetes.rules

import data.kubernetes.allowed_resources

# Resource limits
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits

    msg = sprintf("container '%v' has no resource limits", [container.name])
}

# Security context
deny[msg] {
    input.kind == "Pod"
    not input.spec.securityContext.runAsNonRoot

    msg = "pods must run as non-root user"
}

# Network policies
deny[msg] {
    input.kind == "NetworkPolicy"
    not input.spec.egress
    not input.spec.ingress

    msg = "network policy must specify either ingress or egress rules"
}

# Image pull policy
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.imagePullPolicy == "Always"

    msg = sprintf("container '%v' should use imagePullPolicy: Always", [container.name])
}

# Liveness and readiness probes
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.livenessProbe
    not container.readinessProbe

    msg = sprintf("container '%v' must have liveness and readiness probes", [container.name])
}
