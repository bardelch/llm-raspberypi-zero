# agent.py
import subprocess
from smolagents import CodeAgent

class LocalLlamaCpp:
    def __init__(self):
        self.binary = "/app/llama-main"
        self.model = "/app/models/gemma-2-2b-it-q2_k.gguf"

    def generate(self, prompt: str, max_tokens: int = 256, temp: float = 0.7):
        cmd = [
            self.binary,
            "-m", self.model,
            "-p", prompt,
            "-n", str(max_tokens),
            "--temp", str(temp),
            "--color"  # optional, remove on non-terminal
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stdout.strip()

# Very basic usage - customize as needed
llm = LocalLlamaCpp()
agent = CodeAgent(model=llm, max_iterations=6)  # add tools later

if __name__ == "__main__":
    print("Agent ready. Example query:")
    response = agent.run("Write Python code that prints 'Hello from Pi Zero Docker!'")
    print(response)

