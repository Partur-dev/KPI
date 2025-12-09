const root = document.querySelector(".item-4");

const createCollapse = ({ title, content }) => {
  const details = document.createElement("details");
  const summary = document.createElement("summary");
  summary.textContent = title;
  details.appendChild(summary);

  const contentDiv = document.createElement("div");
  contentDiv.classList.add("details-body");
  contentDiv.innerHTML = content;
  details.appendChild(contentDiv);

  return details;
};

const load = async () => {
  const res = await fetch("/api/data");
  const json = await res.json();

  return json.map(createCollapse);
};

document.addEventListener("DOMContentLoaded", () => {
  const prev = [];

  const update = async () => {
    const items = await load();
    if (JSON.stringify(prev) !== JSON.stringify(items)) {
      root.replaceChildren(...items);
      prev.length = 0;
      prev.push(...items);
    }
  };

  update().then(() => {
    setInterval(async () => {
      const items = await load();
      if (JSON.stringify(prev) !== JSON.stringify(items)) {
        root.replaceChildren(...items);
        prev.length = 0;
        prev.push(...items);
      }
    }, 5000);
  });
});
