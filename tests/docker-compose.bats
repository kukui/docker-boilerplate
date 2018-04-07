setup () {
    load utils
    export $(cat environments/$ENVIRONMENT | grep -v ^# | xargs)
    make dcd
    make dcu
}

teardown () {
    export $(cat environments/$ENVIRONMENT | grep -v ^# | xargs)
    make dcd
}

@test "docker says api up" {
  local service="api"
  local ports="3031/tcp"
  docker_service_status
  return $?
}


@test "api accessible from localhost" {
    local service="api"
    local port=3031
    test_host_port
    return $?
}

@test "docker says www up" {
  local service="api"
  local ports="80/tcp"
  docker_service_status
  local ports="443/tcp"
  docker_service_status
  return $?
}

@test "www accessible from localhost" {
    local service="api"
    local port=3031
    test_host_port
    return $?
}


@test "docker says redis up" {
  local service="api"
  local ports="3031/tcp"
  docker_service_status
  return $?
}

@test "redis accessible from localhost" {
    local service="api"
    local port=6379
    test_host_port
    return $?
}

@test "docker says db up" {
  local service="api"
  local ports="5432/tcp"
  docker_service_status
  return $?
}

# should I make ip address an option here?
@test "db accessible from localhost" {
    local service="db"
    local port=5432
    test_host_port
    return $?
}
