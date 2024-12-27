# policies/combined/rules.rego
package combined.rules

import data.docker.rules as docker
import data.kubernetes.rules as kubernetes
import data.common.security as security

# Cross-component validation
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    image := container.image
    not docker.is_allowed_base_image(image)
    msg = sprintf("container '%v' uses unauthorized base image '%v'", [container.name, image])
}

# Security compliance checks
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not security.has_required_security_context(container)
    msg = sprintf("container '%v' missing required security context settings", [container.name])
}

# Resource quota validation
deny[msg] {
    input.kind == "Namespace"
    not input.spec.resourceQuota
    msg = "namespace must have resource quotas defined"
}
