resource "kubernetes_config_map" "nfs_read_ahead_rule" {
  count = var.enable_node_tuning ? 1 : 0

  metadata {
    name      = "read-ahead-rule"
    namespace = var.namespace.name
  }

  data = {
    "90-nfs-readahead.rules" = <<-EOT
      SUBSYSTEM=="bdi"
      ACTION=="add"
      PROGRAM="/usr/bin/awk -v bdi=$kernel 'BEGIN{ret=1} {if ($4 == bdi) {ret=0}} END{exit ret}' /proc/fs/nfsfs/volumes"
      ATTR{read_ahead_kb}="16384"
    EOT
  }
}

resource "kubernetes_daemonset" "node_tuning" {
  depends_on = [
    kubernetes_config_map.nfs_read_ahead_rule
  ]

  count = var.enable_node_tuning ? 1 : 0

  metadata {
    name      = "hpcc-node-tuning"
    namespace = var.namespace.name
    labels = {
      app = "hpcc-node-tuning"
    }
  }

  spec {
    selector {
      match_labels = {
        name = "hpcc-node-tuning"
      }
    }

    template {
      metadata {
        labels = {
          name = "hpcc-node-tuning"
        }
      }

      spec {
        host_pid            = true
        priority_class_name = "system-node-critical"
        container {
          name              = "node-tuning-complete"
          image             = "busybox:1.34"
          image_pull_policy = "Always"
          resources {
            limits = {
              cpu    = "20m"
              memory = "16Mi"
            }
            requests = {
              cpu    = "10m"
              memory = "8Mi"
            }
          }
          command = ["/bin/sh", "-c", "--"]
          args    = ["echo `date` --- node tuning completed successfully; while true; do echo `date` --- sleeping 1 hour && sleep 3600; done"]
        }
        init_container {
          name              = "node-udev-edit"
          image             = "debian:bullseye-slim"
          image_pull_policy = "Always"
          resources {
            limits = {
              cpu    = "1000m"
              memory = "64Mi"
            }
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
          }
          security_context {
            privileged = true
          }
          volume_mount {
            mount_path = "/tmp"
            name       = "udev-read-ahead"
          }
          volume_mount {
            name       = "host-mount"
            mount_path = "/mnt/azure"
          }
          command = ["/bin/sh", "-c", "--"]
          args    = ["cp /tmp/90-nfs-readahead.rules /mnt/azure/90-nfs-readahead.rules; /usr/bin/nsenter -m/proc/1/ns/mnt -- udevadm control --reload"]
        }
        volume {
          name = "udev-read-ahead"
          config_map {
            name = "read-ahead-rule"
          }
        }
        volume {
          name = "host-mount"
          host_path {
            path = "/etc/udev/rules.d/"
          }
        }
      }
    }
  }
}