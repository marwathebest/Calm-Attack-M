# Bloom companion server

Bloom is the optional AI companion in Calm Attack. This small server sits between the app and the OpenAI API, so the API key never ships inside the open-source app.

- `companion_prompt.md` holds Bloom's instructions: personality, tone and safety rules. Edit it to change how Bloom talks. The server loads it at startup and sends it with every request.
- `src/index.ts` is the server. It adds the instructions, sends the chat to the model, and returns the reply.

The app keeps the conversation only in memory while the chat screen is open. Nothing is stored on the server.

## Run it locally

You need Node.js 23.6 or newer (it runs TypeScript directly) and an OpenAI API key.

```bash
npm install
```

```bash
OPENAI_API_KEY=your-key npm start
```

The server listens on `http://localhost:8787`. Check it with:

```bash
curl http://localhost:8787/health
```

Then run the app pointed at it:

```bash
flutter run --dart-define=COMPANION_URL=http://localhost:8787
```

On an Android emulator, use `http://10.0.2.2:8787` instead of `localhost`.

## Settings

| Variable | Required | What it does |
|---|---|---|
| `OPENAI_API_KEY` | yes | Your OpenAI API key |
| `OPENAI_MODEL` | no | Which model to use (default `gpt-5.5`). Set it to any chat model your account can use. |
| `APP_TOKEN` | no | If set, the app must send it. Build the app with `--dart-define=COMPANION_TOKEN=...` |
| `PORT` | no | Port to listen on (default `8787`) |

## Deploy

Any host that runs Node.js works, for example Render, Railway, Fly.io or a small VPS. Set `OPENAI_API_KEY` as a secret on the host, never in the code. Then build the app with `--dart-define=COMPANION_URL=https://your-server-address`.

Because the app is open source, anyone can read `COMPANION_TOKEN` from a released app, so treat it as a light filter, not real security. The server also limits each address to 12 messages a minute. Set a monthly usage limit on your OpenAI account as well.

## Safety

- Bloom always says it's an AI, not a therapist, and points people to emergency services when there are signs of danger.
- If the model refuses or the API fails, the server returns a calm breathing prompt and advice to call local emergency services, so the user is never left without a reply.

Typecheck with:

```bash
npx tsc --noEmit -p .
```
