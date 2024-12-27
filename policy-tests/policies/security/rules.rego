# policies/security/rules.rego
package security.rules

# CVE checking
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    cve := check_cve(container.image)
    cve.severity == "HIGH"
    msg = sprintf("container '%v' uses image with HIGH severity CVE: %v", [container.name, cve.id])
}

# Sensitive data exposure
deny[msg] {
    input.kind == "Secret"
    not input.metadata.annotations["encryption"]
    msg = "secrets must be encrypted at rest"
}

# Pod security standards
deny[msg] {
    input.kind == "Pod"
    violation := check_pod_security_standards(input)
    msg = sprintf("pod security violation: %v", [violation])
}

# Network policy enforcement
deny[msg] {
    input.kind == "Deployment"
    namespace := input.metadata.namespace
    not has_network_policy(namespace)
    msg = sprintf("namespace '%v' must have a NetworkPolicy", [namespace])
}
