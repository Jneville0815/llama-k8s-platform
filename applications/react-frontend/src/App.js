import React from "react";
import ChatInterface from "./components/ChatInterface";

function App() {
  return (
    <div
      style={{
        minHeight: "100vh",
        backgroundColor: "#f5f5f5",
        padding: "20px",
      }}
    >
      <div
        style={{
          maxWidth: "800px",
          margin: "0 auto",
          backgroundColor: "white",
          borderRadius: "10px",
          boxShadow: "0 2px 10px rgba(0,0,0,0.1)",
          overflow: "hidden",
        }}
      >
        <header
          style={{
            backgroundColor: "#2c3e50",
            color: "white",
            padding: "20px",
            textAlign: "center",
          }}
        >
          <h1 style={{ margin: 0 }}>🦙 LLaMA Chat</h1>
          <p style={{ margin: "5px 0 0 0", opacity: 0.8 }}>
            Powered by LLaMA 3.2-3B on Kubernetes
          </p>
        </header>
        <ChatInterface />
      </div>
    </div>
  );
}

export default App;
