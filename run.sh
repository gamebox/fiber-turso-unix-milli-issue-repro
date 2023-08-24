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
TURSO_PID=$!

echo "Starting up the server"
mv fiberGoTursoMillis "$TMP/"
"$TMP/fiberGoTursoMillis" > "$TMP/server-stdout" 2> "$TMP/server-stderr" &
SERVER_PID=$!

echo "Started server"
echo "DB and Logs can be found at: $TMP"
echo "This path has been copied to your clipboard"
echo $TMP | pbcopy

_terminate() {
    echo "Killing server"
    kill -TERM "$SERVER_PID" 2>/dev/null ;
    wait "$SERVER_PID" 2>/dev/null ;
    echo "Killing turso"
    kill -TERM "$TURSO_PID" 2>/dev/null ;
    wait "$TURSO_PID" 2>/dev/null ;
}
trap _terminate SIGINT SIGTERM SIGKILL

wait "$SERVER_PID"

