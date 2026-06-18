import express from "express";
import morgan from "morgan";
import path from "path";
import FAQ from "./data/faq.json" with { type: "json" };

const app = express();

app.use(morgan("dev"));
app.use(express.static("public"));

app.set("view engine", "ejs");
app.set("views", path.join(import.meta.dirname, "views"));

app.get("/faq", (req, res) => {
  const data = {
    faq: FAQ,
  };
  res.render("faq", data);
});

app.use((req, res) => {
  res.status(404).render("404");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
