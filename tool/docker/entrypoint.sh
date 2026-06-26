#!/bin/sh
set -e

# Start HAProxy as a background daemon
echo "Starting HAProxy local service proxy..."
haproxy -f /app/tool/docker/haproxy.cfg -D

# Execute the main container command (passed via CMD in Dockerfile or Compose)
exec "$@"
