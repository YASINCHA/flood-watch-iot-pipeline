const express = require("express");
const axios = require("axios");
const fs = require("fs");
const path = require("path");

const app = express();
app.use(express.json());

// ================= CONFIG =================
const API_KEY = "55cf6372f1494409b14235639251704";
const CITY = "Tunis";

// file storage
const FILE_PATH = path.join(__dirname, "history.json");

// ================= STATE =================
let latestData = {
  level: 0,
  risk: "WAITING"
};

// ================= INIT HISTORY FILE =================
if (!fs.existsSync(FILE_PATH)) {
  fs.writeFileSync(FILE_PATH, JSON.stringify([]));
}

// ================= HELPERS =================
function readHistory() {
  try {
    return JSON.parse(fs.readFileSync(FILE_PATH));
  } catch (e) {
    return [];
  }
}

function saveHistory(data) {
  const history = readHistory();

  history.push(data);

  // keep last 100 records only
  if (history.length > 100) {
    history.shift();
  }

  fs.writeFileSync(FILE_PATH, JSON.stringify(history, null, 2));
}

// ================= POST FROM ESP32 =================
app.post("/data", (req, res) => {
  try {
    const { level, risk } = req.body;

    const entry = {
      level,
      risk,
      time: new Date().toISOString()
    };

    latestData = {
      level,
      risk
    };

    saveHistory(entry);

    console.log("📡 DATA RECEIVED:", entry);

    res.status(200).send("OK");
  } catch (err) {
    console.log("❌ POST ERROR:", err.message);
    res.status(500).send("ERROR");
  }
});

// ================= GET CURRENT DATA + WEATHER =================
app.get("/data", async (req, res) => {
  try {
    const weatherRes = await axios.get(
      `http://api.weatherapi.com/v1/current.json?key=${API_KEY}&q=${CITY}&aqi=no`
    );

    const w = weatherRes.data.current;

    const weather = {
      temp: w.temp_c,
      feelslike: w.feelslike_c,
      humidity: w.humidity,
      wind: w.wind_kph,
      pressure: w.pressure_mb,
      condition: w.condition.text
    };

    res.json({
      ...latestData,
      weather
    });

  } catch (err) {
    console.log("❌ WEATHER ERROR:", err.message);

    res.json({
      ...latestData,
      weather: {
        temp: 0,
        feelslike: 0,
        humidity: 0,
        wind: 0,
        pressure: 0,
        condition: "ERROR"
      }
    });
  }
});

// ================= GET HISTORY =================
app.get("/history", (req, res) => {
  const history = readHistory();
  res.json(history);
});

// ================= CLEAR HISTORY =================
app.delete("/history", (req, res) => {
  fs.writeFileSync(FILE_PATH, JSON.stringify([]));
  res.send("🧹 History cleared");
});

// ================= START SERVER =================
const PORT = 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});