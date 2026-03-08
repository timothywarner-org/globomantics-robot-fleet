// Minimal database stub for demo purposes
const sqlite3 = require("sqlite3");
const db = new sqlite3.Database(":memory:");

module.exports = {
  query: (sql, callback) => db.all(sql, callback),
};
