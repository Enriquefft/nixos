#!/usr/bin/env bash
# Quick Ollama benchmark — tests latency and shows GPU vs CPU status

MODEL="gemma3:1b"
ENDPOINT="http://localhost:11434"

echo "=== Ollama GPU/CPU Check ==="
ollama ps 2>/dev/null || echo "Ollama not running!"
echo ""

echo "=== Sending test request to $MODEL ==="
START=$(date +%s%N)

RESPONSE=$(curl -s "$ENDPOINT/api/chat" -d "{
  \"model\": \"$MODEL\",
  \"stream\": false,
  \"options\": {\"num_predict\": 80},
  \"messages\": [
    {\"role\": \"system\", \"content\": \"You are a gladiator. Respond with JSON: {direction, speed, action, reasoning}\"},
    {\"role\": \"user\", \"content\": \"HP=80% OppHP=60% Dist=3.2m Me: atkCD=0 blkCD=0\"}
  ]
}")

END=$(date +%s%N)
ELAPSED_MS=$(( (END - START) / 1000000 ))

echo ""
echo "=== Results ==="
echo "Latency: ${ELAPSED_MS}ms"
echo ""

# Show processor info again (model now loaded)
echo "=== Processor Check ==="
ollama ps 2>/dev/null
echo ""

# Extract response content
echo "=== Response ==="
echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['message']['content'])" 2>/dev/null || echo "$RESPONSE" | head -c 500

echo ""
echo "--- Expected performance ---"
echo "GPU: < 2s"
echo "CPU: 5-15s"
