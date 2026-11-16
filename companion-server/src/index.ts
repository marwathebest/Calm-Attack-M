/**
 * Calm Attack companion server.
 *
 * A small HTTP server that sits between the app and the OpenAI API, so the
 * API key never ships inside the open-source app. The app sends the chat
 * so far; the server adds the companion's instructions, asks the model for
 * the next reply and returns it.
 *
 *   POST /chat   body: { "messages": [{ "role": "user" | "assistant", "content": "..." }] }
 *                reply: { "reply": "..." }
 *   GET  /health reply: { "ok": true }
 *
 * Environment:
 *   OPENAI_API_KEY  required - your OpenAI API key
 *   OPENAI_MODEL    optional - model name, defaults to gpt-5.5
 *   APP_TOKEN       optional - if set, requests must send header `x-app-token`
 *   PORT            optional - defaults to 8787
 */
import { readFileSync } from "node:fs";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";

import OpenAI from "openai";
import type { ChatCompletionMessageParam } from "openai/resources/chat/completions";

const here = path.dirname(fileURLToPath(import.meta.url));
const SYSTEM_PROMPT = readFileSync(
  path.join(here, "..", "companion_prompt.md"),
  "utf8",
);

const MODEL = process.env.OPENAI_MODEL ?? "gpt-5.5";
const PORT = Number(process.env.PORT ?? 8787);
const APP_TOKEN = process.env.APP_TOKEN;

// Limits that keep requests small and protect the API budget.
const MAX_MESSAGES = 40;
const MAX_MESSAGE_CHARS = 2000;
const MAX_BODY_BYTES = 100_000;
const REQUESTS_PER_MINUTE = 12;

/** Shown when the model declines or something goes wrong. */
const SAFE_FALLBACK =
  "I'm here with you. Let's take one slow breath together: in for 3, hold for 3, out for 3. " +
  "If you feel unsafe or think this could be a medical emergency, please call your local emergency number now.";

// Reads OPENAI_API_KEY from the environment. Created lazily so the server
// can still start (and answer /health) before a key is configured.
let client: OpenAI | undefined;
function openai(): OpenAI {
  client ??= new OpenAI();
  return client;
}

// Very small in-memory rate limiter, per client IP.
const recentRequests = new Map<string, number[]>();
function allowRequest(ip: string): boolean {
  const now = Date.now();
  const window = (recentRequests.get(ip) ?? []).filter((t) => now - t < 60_000);
  if (window.length >= REQUESTS_PER_MINUTE) {
    recentRequests.set(ip, window);
    return false;
  }
  window.push(now);
  recentRequests.set(ip, window);
  return true;
}

type ChatTurn = { role: "user" | "assistant"; content: string };

/** Checks the app's message list. Returns an error string if invalid. */
function parseMessages(body: unknown): ChatTurn[] | string {
  if (typeof body !== "object" || body === null || !("messages" in body)) {
    return "Body must be an object with a messages array.";
  }
  const raw = (body as { messages: unknown }).messages;
  if (!Array.isArray(raw) || raw.length === 0) {
    return "messages must be a non-empty array.";
  }
  // Keep only the most recent part of long chats.
  const messages: ChatTurn[] = [];
  for (const m of raw.slice(-MAX_MESSAGES)) {
    if (
      typeof m !== "object" ||
      m === null ||
      (m.role !== "user" && m.role !== "assistant") ||
      typeof m.content !== "string" ||
      m.content.trim() === ""
    ) {
      return "Each message needs a role of user or assistant and text content.";
    }
    messages.push({ role: m.role, content: m.content.slice(0, MAX_MESSAGE_CHARS) });
  }
  // The conversation must start with the user and end with the user.
  while (messages.length > 0 && messages[0].role !== "user") messages.shift();
  if (messages.length === 0 || messages[messages.length - 1].role !== "user") {
    return "The last message must come from the user.";
  }
  return messages;
}

async function companionReply(messages: ChatTurn[]): Promise<string> {
  const input: ChatCompletionMessageParam[] = [
    // The instructions file is the companion's "skill", sent first every time.
    { role: "developer", content: SYSTEM_PROMPT },
    ...messages,
  ];
  const completion = await openai().chat.completions.create({
    model: MODEL,
    messages: input,
  });

  const message = completion.choices[0]?.message;
  if (!message || message.refusal) return SAFE_FALLBACK;
  return message.content?.trim() || SAFE_FALLBACK;
}

function send(res: ServerResponse, status: number, data: unknown): void {
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    // The Flutter web build calls this from the browser.
    "access-control-allow-origin": "*",
    "access-control-allow-headers": "content-type, x-app-token",
    "access-control-allow-methods": "POST, GET, OPTIONS",
  });
  res.end(JSON.stringify(data));
}

async function readBody(req: IncomingMessage): Promise<string> {
  let size = 0;
  const chunks: Buffer[] = [];
  for await (const chunk of req) {
    size += (chunk as Buffer).length;
    if (size > MAX_BODY_BYTES) throw new Error("too large");
    chunks.push(chunk as Buffer);
  }
  return Buffer.concat(chunks).toString("utf8");
}

const server = createServer(async (req, res) => {
  if (req.method === "OPTIONS") return send(res, 204, {});
  if (req.method === "GET" && req.url === "/health") return send(res, 200, { ok: true });
  if (req.method !== "POST" || req.url !== "/chat") return send(res, 404, { error: "Not found" });

  if (APP_TOKEN && req.headers["x-app-token"] !== APP_TOKEN) {
    return send(res, 401, { error: "Unauthorized" });
  }
  const ip = req.socket.remoteAddress ?? "unknown";
  if (!allowRequest(ip)) {
    return send(res, 429, { error: "Too many messages. Please wait a moment." });
  }

  let body: unknown;
  try {
    body = JSON.parse(await readBody(req));
  } catch {
    return send(res, 400, { error: "Invalid JSON body." });
  }
  const messages = parseMessages(body);
  if (typeof messages === "string") return send(res, 400, { error: messages });

  try {
    const reply = await companionReply(messages);
    return send(res, 200, { reply });
  } catch (error) {
    if (error instanceof OpenAI.RateLimitError) {
      console.error("OpenAI rate limit or quota reached");
      return send(res, 503, { error: "The companion is busy. Please try again shortly.", reply: SAFE_FALLBACK });
    }
    if (error instanceof OpenAI.AuthenticationError) {
      console.error("OpenAI API key is missing or invalid");
    } else if (error instanceof OpenAI.APIError) {
      console.error(`OpenAI API error ${error.status}: ${error.message}`);
    } else {
      console.error("Unexpected error:", error instanceof Error ? error.message : error);
    }
    return send(res, 502, { error: "The companion is unavailable right now.", reply: SAFE_FALLBACK });
  }
});

server.listen(PORT, () => {
  console.log(`Calm Attack companion (${MODEL}) listening on http://localhost:${PORT}`);
});
