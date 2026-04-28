# Copilot Router

**Your invisible, lightning-fast bridge to local AI.**

Copilot Router is a lightweight Background Engine that takes the power of GitHub Copilot and allows you to seamlessly plug it into any local AI interface (like Copilot Router, Cline or generic OpenAI-compatible dashboards) without limitations or complicated setup. 

We handle all the technical heavy lifting, infinite context bypasses, and node-spawning behind the scenes, so you can just talk to your AI.

---

## ⚡ What does it do?
Normally, connecting command-line AI tools to visual dashboards involves fighting Windows limits, setting up Python environments, or dealing with timeout breakages.

**Copilot Router solves this by:**
1. Running a silent, ultra-fast `Bun` server in your background.
2. Intercepting your chat messages from any compatible interface (using port `3099`).
3. Feeding them into your local Copilot engine with zero context limits.
4. Streaming the answer back to your screen in real time.

---

## 🛠️ Quick Installation

Getting started is as simple as double-clicking a file. 

1. **Install Prerequisites**: You just need `Node.js` installed on your machine.
2. **Run the Installer**:
   Double click the `setup.cmd` file. 
   *(It will automatically check your environment and download the necessary tools like `bun` and `@github/copilot` for you).*
3. **Register your Environment (Optional)**:
   Double click `set-router-env.cmd` to instantly register `http://localhost:3099/v1` as your default AI provider in Windows.

---

## 🎮 How to Use 

Everything is controlled by the simple `router.ps1` script (or its shortcut `.cmd` files). You don't need to keep a terminal open!

- **▶️ Start the Hub**: Run `1 - up.cmd` (or `.\router.ps1 up`). The engine will start silently in the background. Your local Cloud is now online!
- **⏹️ Stop the Hub**: Run `2 - down.cmd` (or `.\router.ps1 down`). This safely kills the background process and frees the port.
- **👀 View Logs**: Run `3 - logs.cmd` (or `.\router.ps1 logs`) to see a real-time matrix of the traffic flowing between your UI and the AI.

---

## 🔌 Connecting your Apps
Any app that asks for an `OpenAI API Key` or `Base URL` can now be powered by your Copilot Router.

- **Base URL / Endpoint**: `http://localhost:3099/v1`
- **API Key**: `copilot-router-local-key` *(or any random word, we don't block it)*
- **Model Name**: `gpt-5-mini` *(or whatever your default loader uses)*

---

## 🚑 Troubleshooting

- **"Port 3099 is already in use"**: You probably already have a Hub running. Run `2 - down.cmd` to force-kill it, then start it again.
- **"Network Error / Provider did not respond"**: Ensure you started the Hub (`1 - up.cmd`) before sending messages in your UI. You can run `.\router.ps1 status` to verify if the engine is alive.
- **Is Node/npm missing?**: Download and install the latest LTS version of [Node.js](https://nodejs.org/), then try running `setup.cmd` again.
