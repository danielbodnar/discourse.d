# policies/cost/rules.rego
package cost.rules

# Resource optimization
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    cpu_request := container.resources.requests.cpu
    cpu_limit := container.resources.limits.cpu
    ratio := cpu_limit_to_request_ratio(cpu_request, cpu_limit)
    ratio > 4
    msg = sprintf("container '%v' CPU limit to request ratio too high: %v", [container.name, ratio])
}

# Storage optimization
deny[msg] {
    input.kind == "PersistentVolumeClaim"
    size := parse_storage_size(input.spec.resources.requests.storage)
    size > 100 * 1024 * 1024 * 1024  # 100GB
    not input.metadata.annotations["large-storage-approved"]
    msg = "large storage requests must be approved"
}

# Node affinity optimization
deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.spec.affinity
    msg = "deployments should specify node affinity for cost optimization"
}
