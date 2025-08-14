import React, { useState } from "react";
import axios from "axios";

const ChatInterface = () => {
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const sendMessage = async () => {
    if (!inputMessage.trim()) return;

    const userMessage = { role: "user", content: inputMessage };
    setMessages((prev) => [...prev, userMessage]);
    setInputMessage("");
    setIsLoading(true);

    try {
      const response = await axios.post("/api/chat", {
        message: inputMessage,
        max_tokens: 150,
      });

      const aiMessage = { role: "assistant", content: response.data.response };
      setMessages((prev) => [...prev, aiMessage]);
    } catch (error) {
      console.error("Error sending message:", error);
      const errorMessage = {
        role: "assistant",
        content: "Sorry, I encountered an error. Please try again.",
      };
      setMessages((prev) => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div style={{ height: "600px", display: "flex", flexDirection: "column" }}>
      {/* Chat Messages */}
      <div
        style={{
          flex: 1,
          padding: "20px",
          overflowY: "auto",
          borderBottom: "1px solid #eee",
        }}
      >
        {messages.length === 0 && (
          <div
            style={{ textAlign: "center", color: "#666", marginTop: "100px" }}
          >
            <p>
              👋 Hello! Ask me anything and I'll respond using LLaMA 3.2-3B.
            </p>
            <p style={{ fontSize: "14px" }}>
              Try: "What is Kubernetes?" or "Tell me a joke"
            </p>
          </div>
        )}

        {messages.map((message, index) => (
          <div
            key={index}
            style={{
              marginBottom: "15px",
              display: "flex",
              justifyContent:
                message.role === "user" ? "flex-end" : "flex-start",
            }}
          >
            <div
              style={{
                maxWidth: "70%",
                padding: "12px 16px",
                borderRadius: "18px",
                backgroundColor:
                  message.role === "user" ? "#007bff" : "#e9ecef",
                color: message.role === "user" ? "white" : "#333",
                wordWrap: "break-word",
              }}
            >
              <strong>{message.role === "user" ? "You" : "🦙 LLaMA"}:</strong>
              <div style={{ marginTop: "5px" }}>{message.content}</div>
            </div>
          </div>
        ))}

        {isLoading && (
          <div style={{ display: "flex", justifyContent: "flex-start" }}>
            <div
              style={{
                padding: "12px 16px",
                borderRadius: "18px",
                backgroundColor: "#e9ecef",
                color: "#666",
              }}
            >
              <strong>🦙 LLaMA:</strong>
              <div style={{ marginTop: "5px" }}>Thinking...</div>
            </div>
          </div>
        )}
      </div>

      {/* Input Area */}
      <div style={{ padding: "20px", backgroundColor: "#f8f9fa" }}>
        <div style={{ display: "flex", gap: "10px" }}>
          <textarea
            value={inputMessage}
            onChange={(e) => setInputMessage(e.target.value)}
            onKeyPress={handleKeyPress}
            placeholder="Type your message here..."
            disabled={isLoading}
            style={{
              flex: 1,
              padding: "12px",
              border: "1px solid #ddd",
              borderRadius: "20px",
              resize: "none",
              outline: "none",
              fontFamily: "inherit",
              fontSize: "14px",
            }}
            rows={2}
          />
          <button
            onClick={sendMessage}
            disabled={isLoading || !inputMessage.trim()}
            style={{
              padding: "12px 24px",
              backgroundColor: "#007bff",
              color: "white",
              border: "none",
              borderRadius: "20px",
              cursor: isLoading ? "not-allowed" : "pointer",
              fontSize: "14px",
              opacity: isLoading || !inputMessage.trim() ? 0.6 : 1,
            }}
          >
            Send
          </button>
        </div>
      </div>
    </div>
  );
};

export default ChatInterface;
