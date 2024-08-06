terraform {
    required_providers {
      nsxt = {
          source = "vmware/nsxt"
          version = "3.2.2"
      }
    }

    required_version = ">=1.0.0"
}