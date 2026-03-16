import "dotenv/config";
import fs from "fs";
import admin from "firebase-admin";
import OpenAI from "openai";

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// Embedding model
const EMBED_MODEL = "text-embedding-3-small";

async function embedText(text) {
  const res = await openai.embeddings.create({
    model: EMBED_MODEL,
    input: text,
  });
  return res.data[0].embedding;
}

async function main() {
  const raw = fs.readFileSync("./ucp_data_final.json", "utf-8");
  const items = JSON.parse(raw); // array of {id, text, source}

  console.log("Items:", items.length);

  for (const item of items) {
    if (!item?.id || !item?.text) {
      console.warn("Skipping invalid item:", item);
      continue;
    }

    const embeddingArray = await embedText(item.text);

    const embeddingVector = admin.firestore.FieldValue.vector(embeddingArray);

    await db.collection("kb_chunks").doc(item.id).set({
      id: item.id,
      text: item.text,
      source: item.source ?? "",
      embedding: embeddingVector,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("Uploaded:", item.id, "dim:", embeddingArray.length);
  }

  console.log("Done.");
}

main().catch(console.error);
