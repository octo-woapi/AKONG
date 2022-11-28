terraform {
  required_providers {
    kong = {
      source = "philips-labs/kong"
      version = "5.521.2"
    }
  }
}

provider "kong" {
  kong_admin_uri = "http://kong:8001"
}

resource "kong_service" "monService" {
  name        = "monService"
  protocol    = "http"
  host        = "mockbin.org"
  path        = "/bin/ece3dd4e-3821-4513-a18b-0ba7eccb50ed"
  retries     = 5
  connect_timeout = 1000
  write_timeout   = 2000
  read_timeout    = 3000
}

resource "kong_route" "routeRateLimited" {
  name            = "Route-Limitee"
  protocols       = [ "http" ]
  methods         = [ "GET", "OPTIONS" ]
  hosts           = [ "localhost" ]
  paths           = [ "/ratelimited" ]
  strip_path      = false
  regex_priority  = 1
  service_id  = kong_service.monService.id
}

resource "kong_plugin" "route_rate_limited_plugin" {
  name = "rate-limiting"
  route_id = kong_route.routeRateLimited.id
  config_json = <<EOT
    {
        "minute": 6,
        "policy": "local"
    }
EOT
}

resource "kong_plugin" "file-log" {
    name        = "file-log"   
    config_json = <<EOT
    {
      "path": "/tmp/file.log"
    }
EOT
}
