const item1 = document.querySelector(".item-1");
const item2 = document.querySelector(".item-2");
const item3 = document.querySelector(".item-3");
const item4 = document.querySelector(".item-4");
const item5 = document.querySelector(".item-5");
const item6 = document.querySelector(".item-6");
const item7 = document.querySelector(".item-7");

const task1 = () => {
  const tmp = item5.innerHTML;
  item5.innerHTML = item4.innerHTML;
  item4.innerHTML = tmp;
};

const task2 = () => {
  const width = 5;
  const height = 10;
  const area = (width * height) / 2;
  const el = document.createElement("p");
  el.innerHTML = `Area of the triangle is: ${area}`;
  item3.appendChild(el);
};

const task3 = () => {
  if (document.cookie.includes("largest=")) {
    alert(document.cookie);
    alert("After clicking OK, the cookie will be deleted.");
    document.cookie = "largest=0;expires=Thu, 01 Jan 1970 00:00:00 UTC;";
    document.location.reload();
    return;
  }

  const form = document.createElement("form");

  const input = document.createElement("input");
  input.type = "text";
  input.name = "Numbers";
  input.placeholder = "1, 2, 3, ...";

  const submit = document.createElement("button");
  submit.type = "submit";
  submit.innerHTML = "Submit";

  form.appendChild(input);
  form.appendChild(submit);
  item3.appendChild(form);

  form.onsubmit = (e) => {
    e.preventDefault();
    const numbers = input.value.split(",").map((num) => Number(num.trim()));

    if (numbers.some(isNaN)) {
      alert("Please enter valid numbers separated by commas.");
      return;
    }

    const largest = Math.max(...numbers);
    document.cookie = `largest=${largest};`;
    alert(`The largest number is: ${largest}`);
  };
};

const task4 = () => {
  const form = document.createElement("form");

  const radio1 = document.createElement("input");
  radio1.type = "radio";
  radio1.name = "option";
  radio1.value = "400";
  radio1.id = "option1";

  const label1 = document.createElement("label");
  label1.htmlFor = "option1";
  label1.innerHTML = "400";

  const radio2 = document.createElement("input");
  radio2.type = "radio";
  radio2.name = "option";
  radio2.value = "600";
  radio2.id = "option2";

  const label2 = document.createElement("label");
  label2.htmlFor = "option2";
  label2.innerHTML = "600";

  const submit = document.createElement("button");
  submit.type = "submit";
  submit.innerHTML = "Submit";

  form.appendChild(radio1);
  form.appendChild(label1);
  form.appendChild(radio2);
  form.appendChild(label2);
  form.appendChild(submit);
  item6.appendChild(form);

  form.onsubmit = (e) => {
    e.preventDefault();
    const selectedOption = form.option.value;
    localStorage.setItem("font-weight", Number(selectedOption));
  };

  document.addEventListener("scroll", () => {
    const fontWeight = localStorage.getItem("font-weight");
    if (fontWeight) {
      item6.style.fontWeight = fontWeight;
    }
  });
};

const task5 = () => {
  const addForm = (target, list, index) => () => {
    target.remove();

    const form = document.createElement("form");

    const input = document.createElement("input");
    input.type = "text";
    input.name = "input";
    input.placeholder = "Type '-clear-' to remove list";

    const submit = document.createElement("button");
    submit.type = "submit";
    submit.innerHTML = "Submit";

    form.appendChild(input);
    form.appendChild(submit);

    const firstChild = list.firstChild;
    if (firstChild) {
      list.insertBefore(form, firstChild);
    } else {
      list.appendChild(form);
    }

    form.onsubmit = (e) => {
      e.preventDefault();

      if (input.value === "-clear-") {
        localStorage.removeItem(`list-${index}`);
        document.location.reload();
        return;
      }

      const item = document.createElement("li");
      item.innerHTML = input.value;
      list.appendChild(item);

      const existing = localStorage.getItem(`list-${index}`);
      const arr = existing ? JSON.parse(existing) : [];
      arr.push(input.value);

      localStorage.setItem(`list-${index}`, JSON.stringify(arr));

      input.value = "";
    };
  };

  [item1, item2, item3, item4, item5, item6, item7].forEach((item, i) => {
    const list = document.createElement("ul");
    list.className = "list";

    const it = localStorage.getItem(`list-${i}`);
    if (it) {
      const json = JSON.parse(it);
      for (const entry of json) {
        const p = document.createElement("li");
        p.innerHTML = entry;
        list.appendChild(p);
      }

      item.innerHTML = "";
      item.appendChild(list);
    } else {
      item.appendChild(list);
    }

    const target = document.createElement("input");
    target.value = "Select to add form";
    item.appendChild(target);

    target.addEventListener("select", addForm(target, list, i), { once: true });
  });
};

document.addEventListener("DOMContentLoaded", () => {
  task1();
  task2();
  task3();
  task4();
  task5();
});
