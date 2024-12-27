# policies/docker/rules.rego
package docker.rules

import data.docker.allowed_images

# Deny rules for Docker
deny[msg] {
    input.kind == "Dockerfile"
    not valid_base_image

    msg = sprintf("base image '%v' is not allowed", [input.from])
}

deny[msg] {
    input.kind == "Dockerfile"
    not has_maintainer

    msg = "Dockerfile must have a MAINTAINER label"
}

deny[msg] {
    input.kind == "Dockerfile"
    not has_healthcheck

    msg = "Dockerfile must include HEALTHCHECK instruction"
}

# Validation rules
valid_base_image {
    base := input.from
    allowed_images[base]
}

has_maintainer {
    input.labels["maintainer"]
}

has_healthcheck {
    input.healthcheck
}

# Security rules
deny[msg] {
    input.user == "root"
    msg = "running as root is not allowed"
}

deny[msg] {
    input.expose[_] == "22"
    msg = "exposing SSH port 22 is not allowed"
}
