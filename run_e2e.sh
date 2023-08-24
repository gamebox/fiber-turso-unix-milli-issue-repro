#!/usr/bin/env sh

export PORT="3003"
export DB_PORT="8082"

if curl -s "http://127.0.0.1:$PORT" ; then
    echo "Server already running on port $PORT.  Please kill that process and try again."
    exit 1
fi

if curl -s "http://127.0.0.1:$DB_PORT" ; then
    echo "DB already running on port $DB_PORT.  Please kill that process and try again."
    exit 1
fi

export TMP="$(mktemp -d)"
export DB_PATH="$TMP/test.db" 
export SQLITE_PATH="http://127.0.0.1:$DB_PORT/"

echo "Building the Go server"
go build >> "$TMP/build-stdout" 2>> "$TMP/build-stderr"

echo "Starting up the Database"
turso dev --db-file "$DB_PATH" --port "$DB_PORT" > "$TMP/db-stdout" 2> "$TMP/db-stderr" &
if [[ "$?" -gt 0 ]];
then
  exit "$?"
fi
echo "Starting up the server"
mv fiberGoTursoMillis "$TMP/"
"$TMP/fiberGoTursoMillis" > "$TMP/server-stdout" 2> "$TMP/server-stderr" &
echo "$?"
echo "Started server"
echo "DB and Logs can be found at: $TMP"
echo "This path has been copied to your clipboard"
echo $TMP | pbcopy

echo "Waiting for server to start up..."
while ! curl -s "http://127.0.0.1:$PORT" > /dev/null; do
  sleep 1
done

echo "Running tests..."
cd ./e2e
HOST="http://127.0.0.1:$PORT" pnpm playwright test "$TEST_FLAGS"
EXIT_CODE=$?

echo "Cleaning up..."
pgrep turso | xargs kill -9
pgrep sqld | xargs kill -9
pgrep fiberGoTursoMillis | xargs kill -9
exit "$EXIT_CODE"

