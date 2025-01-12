#!/bin/bash
set -e

# Wait for PostgreSQL
until pg_isready -h "$DISCOURSE_DB_HOST" -p 5432; do
    echo "Waiting for PostgreSQL..."
    sleep 2
done

# Wait for Redis
until redis-cli -h "$DISCOURSE_REDIS_HOST" ping &>/dev/null; do
    echo "Waiting for Redis..."
    sleep 2
done

# Initialize or migrate database if needed
if [ ! -f /var/lib/discourse/.initialized ]; then
    echo "Initializing Discourse..."
    bundle exec rake db:migrate
    bundle exec rake assets:precompile
    touch /var/lib/discourse/.initialized
else
    echo "Running migrations..."
    bundle exec rake db:migrate
fi

# Start Discourse
exec "$@"
