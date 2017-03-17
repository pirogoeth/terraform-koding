data "ignition_filesystem" "ephemeral" {
    name = "ephemeral"
    mount {
        device = "${var.ephemeral_node}"
        format = "btrfs"
    }
}

data "ignition_systemd_unit" "ephemeral-opt" {
    name = "opt.mount"
    enable = "true"
    content = "[Mount]\nWhat=${var.ephemeral_node}\nWhere=/opt/\nType=btrfs\n\n[Install]\nRequiredBy=local-fs.target"
}

data "ignition_file" "hostname" {
    filesystem = "root"
    path = "/etc/hostname"
    mode = 420,
    content {
        content = "koding.${var.base_domain}"
    }
}

data "ignition_user" "core" {
    name = "core"
    ssh_authorized_keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFjFgRovyYevtIVH9eQC+UwZIPlhg2ngeHANpGVG7SW/guT2JxERJybonuzRrNLnojVjCjeNe5D33vRd116b3Cxn5skfwNs6/8WUE9IsWn/0LQrEjQhJTCg7inLys7xbwczO6P2b08+iqNqdvH2/7Mvh73A6GabHaVfwYP//uYzC7+ABQgvYxyCHnl+5r7eXnMDdypajeET0DnM9wXBF+IfXW2AsnikiQr53aUa0c120tx6aol8pIUyJjb3BT9Xz2wFQ4myBh5PGkQ264CmzmYlDRYb754NWXJcNzCmu230s+FKLBtgP4BYosBAd1cT5GACXqt7M0af6sN8seZU3or thrawn01@gmail.com",
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCSCTVeWsvurEXkKIvyGTiUlKO0AexKDpK4I4iFEbgyjhFn9rhs07lMxWHLZnNNRNoJmLZafcgMGpkOsb+7B9N4wnWhWDNK3Aqff1oVl+s5vIKHnuQC15vrsfMIWSl9pfVLqAMIpkMfI15QdaBELZmhATreOdc2rJg32KCd7ICnu0waGfMkHCFp94PR36YjS+kLx+593jQlhM12DdytWcEnRrovXj4xtD4zlDnXnT3kDjyGevlQAqS01IuM6Kod2/+Ph40hFEGVUsyDnJKQ8V5Z3Ui9jGWrZGaCI0Gvx2kcN8q2LiLlNUHsfNL6ENY1HkU7hIGjlQ6bLCFxjpYy77UV seanj-yubihsm"
    ]
}

data "ignition_config" "coreos" {
    filesystems = [
        "${data.ignition_filesystem.ephemeral.id}"
    ]

    systemd = [
        "${data.ignition_systemd_unit.ephemeral-opt.id}"
    ]

    files = [
        "${data.ignition_file.hostname.id}"
    ]

    users = [
        "${data.ignition_user.core.id}"
    ]
}
