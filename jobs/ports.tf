locals {
  ports = {
    launcher      = 9090
    jupyter_oauth = 4180
    jupyter       = 8899
    alphaa        = 8000
    o3000y_rest   = 8083
    o3000y_grpc   = 4327
    openwebui     = 8082
    hyperdx       = 8080
    foliozzz      = 8085
    nats          = 4222
    nats_leaf     = 4223
    nats_leaf_ws  = 4224
    nats_chat     = 8086
    llm_gateway   = 8090
    marimo_oauth  = 4181
    marimo        = 8800
    finadvisor    = 8091
    postgresql    = 5432
    mailpit_smtp  = 1025
    mailpit_ui    = 8025
    # HyperDX internal (not configurable, documented only)
    # otel_grpc   = 4317
    # otel_http   = 4318
    # hdx_metrics = 8888
  }
}
