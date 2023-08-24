package main

import (
	"database/sql"
	_ "embed"
	"log"
	"os"

	json "github.com/goccy/go-json"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/template/html/v2"
	_ "github.com/libsql/libsql-client-go/libsql"
	_ "modernc.org/sqlite"
)

type Controller struct {
    db *sql.DB
}

type NullInt64 struct {
	sql.NullInt64
}

func (ni *NullInt64) MarshalJSON() ([]byte, error) {
	if !ni.Valid {
		return []byte("null"), nil
	}
	return json.Marshal(ni.Int64)
}

type Data struct {
    Id int `json:"id"`
    SomeField NullInt64 `json:"some_field"`
}

//go:embed schema.sql
var dbCreateQuery string

func main() {
	var dbPath string
	dbPathFromEnv, exists := os.LookupEnv("SQLITE_PATH")
	if exists {
		dbPath = dbPathFromEnv
	} else {
		dbPath = "file:sqlite.db"
	}
    log.Printf("Opening DB at path %s", dbPath)
	database, err := sql.Open("libsql", dbPath)
	if err != nil {
		log.Println(err.Error())
		log.Fatalln("Could not read DB")
	}
	err = database.Ping()
	if err != nil {
		log.Fatalf("No database: %s", err.Error())
	}

    _, err = database.Exec(dbCreateQuery)
    if err != nil {
        log.Fatalf("Could not create schema: %s", err.Error())
    }

    ctrl := Controller{db:database}

	viewEngine := html.New("./templates", ".html")
    app := fiber.New(fiber.Config{
        Views: viewEngine,
        ViewsLayout: "base",
    })

    app.Get("/", ctrl.renderTemplate)
    app.Post("/data", ctrl.createData)

    log.Fatalln(app.Listen(":3003"))
}

func (ctrl *Controller) renderTemplate(c *fiber.Ctx) error {
    data, err := ctrl.getData()
    if err != nil {
        return c.Render("error", fiber.Map{
            "Error": err.Error(),
        })
    }
    return c.Render("index", fiber.Map{
        "Data": data,
    });
}

func (ctrl *Controller) createData(c *fiber.Ctx) error {
    err := ctrl.writeData()
    if err != nil {
        return c.Render("error", fiber.Map{
            "Error": err.Error(),
        })
    }
    return c.Redirect("/")
} 

func (ctrl *Controller) writeData() error {
    _, err := ctrl.db.Exec("INSERT INTO data (some_field) VALUES (1000000)")
    if err != nil {
        return err
    }
    return nil
}

func (ctrl *Controller) getData() ([]Data, error) {
    rows, err := ctrl.db.Query("SELECT id, some_field FROM data;")
    datas := make([]Data, 0, 10)
    if err != nil {
        return datas, nil
    }

    for rows.Next() {
        data := Data{}
        err = rows.Err()
        if err != nil {
            return datas, err
        }
        err = rows.Scan(
            &data.Id,
            &data.SomeField,
        )
        if err != nil {
            return datas, err
        }
        datas = append(datas, data)
    }
    return datas, err
}
