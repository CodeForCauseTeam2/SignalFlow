const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

app.post("/fix", async (req, res) => {
  try {
    const { words } = req.body;

    if (!Array.isArray(words)) {
      return res.status(400).json({ error: "words must be an array of strings" });
    }

    const prompt = `Fix grammar and punctuation: ${words.join(" ")}`;

    const r = await fetch("http://127.0.0.1:11434/api/generate", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "llama3",
        prompt: prompt,
        stream: false
      }),
    });

    const data = await r.json();
    res.json({ text: data.response ?? "" });

  } catch (e) {
    res.status(500).json({ error: String(e) });
  }
});

app.listen(3000, "127.0.0.1", () => {
  console.log("Backend running on http://127.0.0.1:3000");
});
