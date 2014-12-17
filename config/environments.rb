configure :development do
    set :database, {adapter: "sqlite3", database: "db/app.sqlite3"}
end

configure :production do
    set :database, {adapter: "sqlite3", database: "db/pro.sqlite3"}
end