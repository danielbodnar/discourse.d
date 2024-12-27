# policies/compliance/rules.rego
package compliance.rules

# GDPR compliance
deny[msg] {
    input.kind == "PersistentVolumeClaim"
    not input.spec.encryption
    msg = "storage must be encrypted for GDPR compliance"
}

# SOC2 compliance
deny[msg] {
    input.kind == "Service"
    input.spec.type == "LoadBalancer"
    not input.spec.loadBalancerSourceRanges
    msg = "LoadBalancer services must specify source ranges for SOC2 compliance"
}

# PCI compliance
deny[msg] {
    input.kind == "Ingress"
    not input.spec.tls
    msg = "ingress must use TLS for PCI compliance"
}
