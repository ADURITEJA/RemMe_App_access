from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

GROQ_API_KEY = "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"
GROQ_MODEL = "llama3-70b-8192"

@app.route('/chat', methods=['POST'])
def chat():
    user_message = request.json.get("message")
    if not user_message:
        return jsonify({"error": "No message provided"}), 400

    groq_url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {GROQ_API_KEY}"
    }
    data = {
        "model": GROQ_MODEL,
        "messages": [
            {"role": "system", "content": "You are a helpful and medically knowledgeable assistant. Respond with clear, safe medical advice."},
            {"role": "user", "content": user_message}
        ],
        "temperature": 0.5
    }
    response = requests.post(groq_url, headers=headers, json=data)
    if response.status_code == 200:
        reply = response.json()['choices'][0]['message']['content']
        return jsonify({"reply": reply})
    else:
        return jsonify({"error": "Groq API error", "details": response.text}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001) 