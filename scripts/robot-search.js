// WARNING: Intentionally vulnerable for demo purposes
// This file demonstrates CWE-89 (SQL Injection) for the Module 5 enforcement demo
const express = require("express");
const router = express.Router();
const db = require("../db");

router.get("/robots/search", (req, res) => {
  const userInput = req.query.q;
  // CWE-89: SQL Injection — user input concatenated directly into query
  const query = `SELECT * FROM robot_fleet WHERE model LIKE '%${userInput}%'`;
  db.query(query, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

module.exports = router;
