import { spawn } from "node:child_process";
import path from "node:path";

// ============================================================================
// SYSTEM CONFIGURATION
// ============================================================================
const CONFIG = {
    port: 3099,
    modelId: "gpt-5.2", // Internal model passed to Github CLI
    publicRouterModelName: "copilot-router-Network", // Pretty name that appears in OpenClaude terminal
    engineTimeoutMs: 120000,
    bunIdleTimeoutSec: 255, 
    copilotLoaderPath: path.join(process.env.APPDATA || "", "npm", "node_modules", "@github", "copilot", "npm-loader.js"),
    nodeExe: "node" // Forced native node execution
};

// Clean ANSI Escape codes from CLI output
const stripAnsi = (str: string) => str.replace(/[\u001b\u009b][[()#;?]*(?:[0-9]{1,4}(?:;[0-9]{0,4})*)?[0-9A-ORZcf-nqry=><]/g, '');

// ============================================================================
// 1. PROMPT BUILDER (Infinite - No Windows Limits)
// ============================================================================
function buildPrompt(messages: any[]): string {
    const systemMsg = messages.find(m => m.role === 'system');
    const conversation = messages.filter(m => m.role !== 'system');

    const getText = (m: any) => {
        let text = typeof m.content === 'string' ? m.content : (m.content || []).map((p: any) => p.text || '').join('');
        return text.replace(/<system-reminder>[\s\S]*?<\/system-reminder>/g, '').trim();
    };

    let systemBrief = '';
    if (systemMsg) {
        const brief = getText(systemMsg).split('\n').slice(0, 5).join('\n'); // Keep more system context
        systemBrief = `[System]: ${brief}\n\n`;
    }

    // Now we get ALL the history (AI native limit, no more Windows limit)
    const history = conversation.map(m => {
        const role = m.role === 'assistant' ? 'Assistant' : 'User';
        return `${role}: ${getText(m)}`;
    }).join('\n\n');

    const fullPrompt = systemBrief + history + '\n\nAssistant:\n';
    
    console.log(`[🚀 Via STDIN Pipe] Full conversation sent: ${conversation.length} original messages, totaling ~${Math.round(fullPrompt.length/1024)} KB of raw context`);
    return fullPrompt;
}

// ============================================================================
// 2. CLI ORCHESTRATOR (Direct call via pure Node)
// ============================================================================
function callCopilot(prompt: string, model: string, onData: (chunk: string) => void, onEnd: (err: Error | null, fullText: string) => void) {
    const env = { ...process.env };
    delete env.OPENAI_BASE_URL;
    delete env.COPILOT_PROVIDER_BASE_URL;
    delete env.CROSS_OPENAI_BASE_URL;
    delete env.CLAUDE_CODE_USE_OPENAI;
    delete env.ANTHROPIC_BASE_URL;
    env.NO_COLOR = '1';

    // Pipe mode: unlimited context sent via STDIN
    const child = spawn(CONFIG.nodeExe, [
        CONFIG.copilotLoaderPath, 
        '--model', model, 
        '--allow-all-paths', '--allow-all-tools', '-s'
    ], {
        shell: false,
        env,
        timeout: CONFIG.engineTimeoutMs 
    });

    child.stdin.write(prompt);
    child.stdin.end();

    let output = '';

    child.stdout.on('data', (d) => {
        const chunk = stripAnsi(d.toString());
        output += chunk;
        onData(chunk);
    });
    
    child.stderr.on('data', (d) => {
        const txt = stripAnsi(d.toString()).trim();
        if (txt) console.log(`[📡 Cloud Logs] ${txt}`);
    });

    child.on('close', () => onEnd(null, output));
    child.on('error', (err) => onEnd(err, ''));

    const kill = setTimeout(() => { 
        child.kill(); 
        onEnd(new Error('Timeout 90s reached. The provider did not respond in time.'), output); 
    }, 90000);
    
    child.on('close', () => clearTimeout(kill));
}

// ============================================================================
// 3. BUN.SERVE - ULTRA-FAST HTTP ENGINE MANAGING CONTEXT
// ============================================================================
Bun.serve({
    hostname: "0.0.0.0", // Exposing to the whole local network (Wi-Fi/LAN)
    port: CONFIG.port,
    idleTimeout: CONFIG.bunIdleTimeoutSec, 
    async fetch(req) {
        const url = new URL(req.url);

        // Native Global CORS
        if (req.method === "OPTIONS") {
            return new Response(null, {
                headers: {
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "*",
                    "Access-Control-Allow-Headers": "*"
                }
            });
        }

        const corsHeaders = { "Access-Control-Allow-Origin": "*" };

        // Vital status automation
        if (url.pathname === "/") {
            return new Response(`🚀 Copilot Router Core [Bun Edition] operating without limits on port ${CONFIG.port}`, { headers: corsHeaders });
        }

        // Pretend to be the OpenAI ecosystem for the AI tools
        if (url.pathname === "/v1/models") {
            return Response.json({ 
                object: 'list', 
                data: [
                    { id: 'auto', object: 'model', owned_by: 'github' },
                    { id: 'gpt-5.4', object: 'model', owned_by: 'openai' },
                    { id: 'gpt-5.3-codex', object: 'model', owned_by: 'openai' },
                    { id: 'gpt-5.2-codex', object: 'model', owned_by: 'openai' },
                    { id: 'gpt-5.2', object: 'model', owned_by: 'openai' },
                    { id: 'gpt-5.4-mini', object: 'model', owned_by: 'openai' },
                    { id: 'gpt-5-mini', object: 'model', owned_by: 'openai' },
                    { id: 'gpt-4.1', object: 'model', owned_by: 'openai' },
                    { id: 'claude-sonnet-4.6', object: 'model', owned_by: 'anthropic' },
                    { id: 'claude-sonnet-4.5', object: 'model', owned_by: 'anthropic' },
                    { id: 'claude-haiku-4.5', object: 'model', owned_by: 'anthropic' },
                    { id: 'claude-sonnet-4', object: 'model', owned_by: 'anthropic' }
                ] 
            }, { headers: corsHeaders });
        }

        // Main Inference Endpoint
        if (req.method === "POST" && url.pathname === "/v1/chat/completions") {
            const body = await req.json();
            const messages = body.messages || [];
            const stream = body.stream === true;

            // Token savings filter (Claude's silly title generations)
            const lastUser = messages.filter((m: any) => m.role === 'user').pop();
            const lastText = typeof lastUser?.content === 'string' ? lastUser.content : '';
            if (lastText.includes('Generate a concise, sentence-case title')) {
                return Response.json({ choices: [{ message: { role: 'assistant', content: '{"title":"Engine Conversation"}' }, index: 0, finish_reason: 'stop' }] }, { headers: corsHeaders });
            }

            const prompt = buildPrompt(messages);
            const targetModel = (body.model && body.model !== CONFIG.publicRouterModelName) ? body.model : CONFIG.modelId;

            // Modern Streaming Response using ReadableStream (Global Web Standard)
            if (stream) {
                let isClosed = false;
                const streamData = new ReadableStream({
                    start(controller) {
                        callCopilot(prompt, targetModel, (chunk) => {
                            if (isClosed || !chunk.trim()) return;
                            try {
                                const payload = { choices: [{ delta: { content: chunk }, index: 0, finish_reason: null }] };
                                controller.enqueue(`data: ${JSON.stringify(payload)}\n\n`);
                            } catch (e) { isClosed = true; }
                        }, (err) => {
                            if (isClosed) return;
                            try {
                                if (err) {
                                    console.error('[🔥 Critical Error]', err.message);
                                    const errPayload = { choices: [{ delta: { content: "\n[Router Server Error: " + err.message + "]" }, index: 0, finish_reason: 'stop' }] };
                                    controller.enqueue(`data: ${JSON.stringify(errPayload)}\n\n`);
                                } else {
                                    controller.enqueue(`data: ${JSON.stringify({ choices: [{ delta: {}, index: 0, finish_reason: 'stop' }] })}\n\n`);
                                    controller.enqueue('data: [DONE]\n\n');
                                }
                                controller.close();
                            } catch (e) {}
                            isClosed = true;
                        });
                    },
                    cancel() {
                        isClosed = true;
                    }
                });

                return new Response(streamData, {
                    headers: {
                        ...corsHeaders,
                        "Content-Type": "text/event-stream",
                        "Cache-Control": "no-cache",
                        "Connection": "keep-alive"
                    }
                });
            } 
            
            // Buffered Request (no stream)
            return new Promise((resolve) => {
                callCopilot(prompt, targetModel, () => {}, (err, text) => {
                    if (err && !text) {
                        resolve(Response.json({ error: err.message }, { status: 500, headers: corsHeaders }));
                    } else {
                        resolve(Response.json({ choices: [{ message: { role: 'assistant', content: text.trim() || 'No response.' }, index: 0, finish_reason: 'stop' }] }, { headers: corsHeaders }));
                    }
                });
            });
        }

        return new Response("Not Found", { status: 404, headers: corsHeaders });
    }
});

console.log(`
=====================================================
   🔥 Copilot Router [BUN NATIVE STDIN ENGINE]
=====================================================
  Access Granted:   http://localhost:${CONFIG.port}/v1
  Default Model:    ${CONFIG.modelId} (GitHub)
  Shields:          PIPELINE STDIN (INFINITE CONTEXT)
=====================================================
`);
