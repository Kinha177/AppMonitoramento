import express from "express";
import dotenv from "dotenv";
import TelegramBot from "node-telegram-bot-api";

dotenv.config();

const app = express();
app.use(express.json());

// === BOT DO TELEGRAM ===
const bot = new TelegramBot(process.env.BOT_TOKEN, { polling: false });

// === ROTA QUE O FLUTTER VAI ENVIAR ===
// Ex: POST http://SEU_IP:3000/alert
app.post("/alert", async (req, res) => {
  const { message } = req.body;

  if (!message) {
    return res.status(400).json({ error: "Mensagem ausente" });
  }

  try {
    await bot.sendMessage(
      process.env.CHAT_ID,
      `🚨 ALERTA DE MONITORAMENTO:\n\n${message}`
    );
    return res.json({ ok: true });
  } catch (error) {
    console.error("Erro ao enviar alerta para o Telegram:", error);
    return res.status(500).json({ error: "Falha ao enviar alerta" });
  }
});

// SERVIDOR
const PORT = 3000;
app.listen(PORT, () => {
  console.log("BOT Telegram rodando na porta " + PORT);
});
