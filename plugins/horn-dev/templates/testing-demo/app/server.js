// Serveur statique minimal, sans dépendance : sert app/public/ et src/ (module du compteur).
// Port 4731 par défaut (variable PORT pour changer). Utilisé par Playwright via webServer.
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join, normalize } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("..", import.meta.url));
const port = Number(process.env.PORT ?? 4731);
const types = { ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".css": "text/css; charset=utf-8" };

const server = createServer(async (req, res) => {
  const url = new URL(req.url ?? "/", `http://localhost:${port}`);
  let file;
  if (url.pathname === "/") file = join(root, "app", "public", "index.html");
  else if (url.pathname.startsWith("/src/")) file = join(root, normalize(url.pathname));
  else file = join(root, "app", "public", normalize(url.pathname));
  try {
    const body = await readFile(file);
    res.writeHead(200, { "content-type": types[extname(file)] ?? "application/octet-stream" });
    res.end(body);
  } catch {
    res.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
    res.end("Introuvable");
  }
});

server.listen(port, () => console.log(`Démo horn-dev : http://localhost:${port}`));
