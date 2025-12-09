const createFormCollapse = ({ title, content }) => {
  const container = document.createElement("div");
  container.classList.add("form-collapse");

  const row = document.createElement("div");
  row.classList.add("row");

  const deleteButton = document.createElement("button");
  deleteButton.textContent = "Delete";
  deleteButton.addEventListener("click", () => {
    container.remove();
  });

  const summary = document.createElement("input");
  const details = document.createElement("textarea");

  summary.classList.add("big");
  summary.value = title;

  details.value = content;

  summary.placeholder = "Title";
  details.placeholder = "Content";

  details.style.resize = "vertical";

  row.appendChild(deleteButton);
  row.appendChild(summary);

  container.appendChild(row);
  container.appendChild(details);

  return container;
};

const loadInitial = async () => {
  const res = await fetch("/api/data");
  const json = await res.json();

  return json.map(createFormCollapse);
};

const extract = () => {
  const containers = document.querySelectorAll(".form-collapse");
  return Array.from(containers).map((container) => {
    const title = container.querySelector("input").value;
    const content = container.querySelector("textarea").value;
    return { title, content };
  });
};

document.addEventListener("DOMContentLoaded", async () => {
  const formRoot = document.querySelector("#form-root");

  const addButton = document.querySelector("#add-button");
  addButton.addEventListener("click", () => {
    const newItem = createFormCollapse({
      title: "",
      content: "",
    });
    formRoot.appendChild(newItem);
  });

  const submitButton = document.querySelector("#submit-button");
  submitButton.addEventListener("click", async () => {
    const data = extract();
    await fetch("/api/data", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    });
    alert("Data saved successfully!");
  });

  const initial = await loadInitial();
  formRoot.append(...initial);
});
