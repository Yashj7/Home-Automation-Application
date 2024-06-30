const express = require("express");
const mssql = require("mssql");
const crypto = require("crypto");
const http = require("http");

const app = express();
const port = 3001;

const { networkInterfaces } = require("os");

app.use(express.json());

app.use((req, res, next) => {
  const currentTime = new Date().toLocaleString();
  console.log(`[${currentTime}] ${req.method} ${req.url}`);
  next();
});

app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header(
    "Access-Control-Allow-Headers",
    "Origin, X-Requested-With, Content-Type, Accept"
  );
  next();
});

const config = {
  user: "sa",
  password: "yash7000",
  server: "LAPTOP-OV3KG247\\SQLEXPRESS",
  database: "home_automation",
  options: {
    trustServerCertificate: true,
  },
};

// const config = {
//   user: "yash",
//   password: "#Raj7000",
//   server: "home-automation-server.database.windows.net",
//   database: "home_automation_db",
//   options: {
//     trustServerCertificate: true,
//   },
// };

mssql
  .connect(config)
  .then(() => console.log("Connected to MSSQL database"))
  .catch((err) => console.error("Error connecting to MSSQL:", err));

const getIpAddress = () => {
  const interfaces = networkInterfaces();
  for (const interfaceName in interfaces) {
    const interfaceInfo = interfaces[interfaceName];
    for (const iface of interfaceInfo) {
      if (iface.family === "IPv4" && !iface.internal) {
        return iface.address;
      }
    }
  }
  return "localhost";
};

app.listen(port, async () => {
  try {
    const ipAddress = getIpAddress();
    console.log(`Server listening at http://${ipAddress}:${port}`);
  } catch (error) {
    console.error("Error retrieving IP address:", error);
  }
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send("Something broke!");
});

const validMacAddress = "E8:68:E7:2E:BA:58";
const expectedHash = crypto
  .createHash("sha256")
  .update(validMacAddress)
  .digest("hex");

app.get("/device_list", async (req, res) => {
  const { room_id, hash } = req.query;
  try {
    if (!hash) {
      return res.status(400).send("Missing hash");
    }
    const computedHash = crypto
      .createHash("sha256")
      .update(validMacAddress)
      .digest("hex");
    if (computedHash === hash) {
      const result =
        await mssql.query`SELECT device_id,state FROM rooms WHERE room_id = ${room_id}`;
      if (result.recordset.length === 0) {
        return res.status(401).json({ error: "No Details Available" });
      }
      return res.status(200).json(result.recordset);
    } else {
      return res.status(401).send("Unauthorized");
    }
  } catch (error) {
    console.error("Error fetching home details:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.get("/status", async (req, res) => {
  const { device_id, hash } = req.query;
  try {
    if (!hash) {
      return res.status(400).send("Missing hash");
    }
    const computedHash = crypto
      .createHash("sha256")
      .update(validMacAddress)
      .digest("hex");
    if (computedHash === hash) {
      const result =
        await mssql.query`SELECT device_id,state FROM rooms WHERE device_id = ${device_id}`;
      if (result.recordset.length === 0) {
        return res.status(401).json({ error: "No Details Available" });
      }
      return res.status(200).json(result.recordset);
    } else {
      return res.status(401).send("Unauthorized");
    }
  } catch (error) {
    console.error("Error fetching home details:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.get("/login", async (req, res) => {
  const { name, pass } = req.query;
  if (!name || !pass) {
    return res.status(400).json({ error: "Name and pass are required" });
  }

  try {
    const result =
      await mssql.query`SELECT home_id FROM users WHERE name = ${name} AND pass = ${pass}`;
    if (result.recordset.length === 0) {
      return res.status(401).json({ error: "Invalid name or pass" });
    }
    res.json(result.recordset);
  } catch (error) {
    console.error("Error fetching users:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.get("/home", async (req, res) => {
  const { home_id } = req.query;
  try {
    const result =
      await mssql.query`SELECT home_name,room_type,room_id FROM home WHERE home_id = ${home_id}`;
    if (result.recordset.length === 0) {
      return res.status(401).json({ error: "No Details Available" });
    }
    res.json(result.recordset);
  } catch (error) {
    console.error("Error fetching home details:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.get("/room", async (req, res) => {
  const { room_id } = req.query;
  try {
    const result =
      await mssql.query`SELECT * FROM rooms WHERE room_id = ${room_id}`;
    if (result.recordset.length === 0) {
      return res.status(401).json({ error: "No Details Available" });
    }
    res.json(result.recordset);
  } catch (error) {
    console.error("Error fetching room details:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post("/changestate", async (req, res) => {
  const { device_id, state } = req.query;
  try {
    const result =
      await mssql.query`UPDATE rooms SET state = ${state} WHERE device_id = ${device_id}`;
    res.json(result.recordset);
  } catch (error) {
    console.error("Error changing device state:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.get("/devices", async (req, res) => {
  const { home_id } = req.query;
  try {
    const result =
      await mssql.query`SELECT deviceList.device_type, deviceList.device_id FROM deviceList LEFT JOIN rooms ON deviceList.device_id = rooms.device_id WHERE deviceList.home_id = ${home_id} AND rooms.device_id IS NULL`;
    if (result.recordset.length === 0) {
      return res.status(401).json({ error: "No Details Available" });
    }
    res.json(result.recordset);
  } catch (error) {
    console.error("Error fetching device details:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post("/adddevice", async (req, res) => {
  const { room_id, device_id } = req.query;
  try {
    const result =
      await mssql.query`INSERT INTO rooms (room_id, device_type, device_id, state) SELECT ${room_id}, device_type, ${device_id}, 1 FROM devicelist WHERE device_id=${device_id}`;
    res.json(result.recordset);
  } catch (error) {
    console.error("Error adding device :", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post("/deletedevice", async (req, res) => {
  const { device_id } = req.query;
  try {
    const result =
      await mssql.query`DELETE FROM rooms WHERE device_id = ${device_id}`;
    res.json(result.recordset);
  } catch (error) {
    console.error("Error deleting device :", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post("/addroom", async (req, res) => {
  const { home_id, home_name, room_type } = req.query;
  try {
    const result =
      await mssql.query`INSERT INTO home (home_id, home_name, room_type, room_id) SELECT ${home_id}, ${home_name}, ${room_type}, new_room_id FROM (SELECT ${home_id} AS home_id, ${home_name} AS home_name, ${room_type} AS room_type, CAST((100 + RAND() * (1000 - 100 + 1)) AS INT) AS new_room_id) AS new_room
      LEFT JOIN home ON new_room.new_room_id = home.room_id LEFT JOIN rooms ON new_room.new_room_id = rooms.room_id WHERE home.room_id IS NULL AND rooms.room_id IS NULL ORDER BY NEWID() OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;`;
    res.json(result.recordset);
  } catch (error) {
    console.error("Error adding room :", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

app.post("/deleteroom", async (req, res) => {
  const { room_id } = req.query;
  try {
    const result =
      await mssql.query`DELETE FROM rooms WHERE room_id = ${room_id}`;
    await mssql.query`DELETE FROM home WHERE room_id = ${room_id}`;
    res.json(result.recordset);
  } catch (error) {
    console.error("Error deleting device :", error);
    res.status(500).json({ error: "Internal server error" });
  }
});
