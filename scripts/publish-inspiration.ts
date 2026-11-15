// Publish only the browser app and public catalogue, never personal review files.
const output = Deno.env.get("QUARTO_PROJECT_OUTPUT_DIR") || "_site";
const destination = `${output}/inspiration`;
await Deno.mkdir(destination, { recursive: true });
for (const file of ["index.html", "review.css", "review.js", "model.js", "catalog.js"]) {
  await Deno.copyFile(`tools/collection-review/${file}`, `${destination}/${file}`);
}
console.log("Published inspiration reviewer: five public app files only.");
