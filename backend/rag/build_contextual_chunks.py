import os
import json
from pathlib import Path
from dotenv import load_dotenv
from openai import OpenAI

RAG_DIR = Path(__file__).resolve().parent
load_dotenv(RAG_DIR / ".env")

client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

PROCESSED_DIR = RAG_DIR / "processed"
CHUNK_FILES = [
    "chunks_isa_조세특례제한법91조18.json",
    "chunks_pension_소득세법59조3.json",
    "chunks_연금저축계좌_상품설명서.json",
    "chunks_외국인종합소득세신고안내.json",
]

PROMPT_TEMPLATE = """You are an AI assistant specialized in analyzing financial documents.
Here is the whole document:
<document>
{whole_document}
</document>

Here is the chunk we want to situate within the whole document:
<chunk>
{chunk_content}
</chunk>

Please provide a short context (1-2 sentences) to situate this chunk within the whole document.
Do not summarize the chunk itself. Instead, clarify what document it comes from and its role or context in the overall document.
If the chunk is written in Korean, generate the context in Korean.
If the chunk is written in English, generate the context in English.
Return ONLY the generated 1-2 sentence context, nothing else.
"""

def generate_context(whole_doc: str, chunk_text: str) -> str:
    prompt = PROMPT_TEMPLATE.format(whole_document=whole_doc, chunk_content=chunk_text)
    
    response = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[
            {"role": "user", "content": prompt}
        ],
        temperature=0.0
    )
    return response.choices[0].message.content.strip()

def main():
    if not os.environ.get("OPENAI_API_KEY"):
        print("Error: OPENAI_API_KEY is not set.")
        return

    for fname in CHUNK_FILES:
        input_path = PROCESSED_DIR / fname
        output_path = PROCESSED_DIR / f"contextual_{fname}"
        
        if not input_path.exists():
            print(f"File not found: {input_path}")
            continue
            
        print(f"Processing {fname}...")
        with open(input_path, "r", encoding="utf-8") as f:
            chunks = json.load(f)
            
        # Reconstruct the whole document
        whole_doc = "\n\n".join([c["text"] for c in chunks])
        
        contextual_chunks = []
        for i, chunk in enumerate(chunks):
            chunk_text = chunk["text"]
            print(f"  Generating context for chunk {i+1}/{len(chunks)}...")
            context = generate_context(whole_doc, chunk_text)
            
            # Form contextual text
            contextual_text = f"<context>\n{context}\n</context>\n\n{chunk_text}"
            
            new_chunk = chunk.copy()
            new_chunk["contextual_text"] = contextual_text
            new_chunk["context_summary"] = context
            contextual_chunks.append(new_chunk)
            
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(contextual_chunks, f, ensure_ascii=False, indent=2)
        print(f"Saved to {output_path}")

if __name__ == "__main__":
    main()
