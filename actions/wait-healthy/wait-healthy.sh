#!/usr/bin/env bash
# Poll `docker inspect` until the container is healthy.
#
# Required env: CONTAINER. Optional env: TIMEOUT (seconds, default 60).
# Exit codes: 0 healthy, 1 unhealthy/exited/timeout, 2 no HEALTHCHECK defined.
set -euo pipefail

: "${CONTAINER:?CONTAINER is required}"
TIMEOUT="${TIMEOUT:-60}"

fail() {
  echo "::error::$1"
  echo "----- last logs of ${CONTAINER} -----"
  docker logs --tail 50 "$CONTAINER" 2>&1 || true
  exit 1
}

has_healthcheck=$(docker inspect --format '{{if .State.Health}}yes{{else}}no{{end}}' "$CONTAINER")
if [ "$has_healthcheck" != "yes" ]; then
  echo "::error::Container ${CONTAINER} has no HEALTHCHECK defined"
  exit 2
fi

deadline=$((SECONDS + TIMEOUT))
while [ "$SECONDS" -lt "$deadline" ]; do
  running=$(docker inspect --format '{{.State.Running}}' "$CONTAINER")
  status=$(docker inspect --format '{{.State.Health.Status}}' "$CONTAINER")

  [ "$running" = "true" ] || fail "Container ${CONTAINER} exited before becoming healthy"

  case "$status" in
    healthy)
      echo "Container ${CONTAINER} is healthy after ${SECONDS}s"
      exit 0
      ;;
    unhealthy)
      fail "Container ${CONTAINER} is unhealthy"
      ;;
  esac

  sleep 1
done

fail "Timed out after ${TIMEOUT}s waiting for ${CONTAINER} to become healthy (last status: ${status})"
