# fiber-turso-unix-milli-issue-repro
A minimal reproduction of the unix millisecond scan issue with Go libsql driver

To run this test, run the following in your shell:

```sh 
go mod tidy
cd e2e
pnpm install
cd ..
TEST_FLAGS="--headed" sh run_e2e.
```
