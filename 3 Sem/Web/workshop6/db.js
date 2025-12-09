import { readFile, writeFile } from "node:fs/promises";

const path = new URL("./data.json", import.meta.url);
const data = JSON.parse(await readFile(path, "utf-8"));
const save = () => writeFile(path, JSON.stringify(data, null, 2), "utf-8");

export const db = {
  get: () => data,
  set: async (newData) => {
    data.length = 0;
    data.push(...newData);
    await save();
  },
};
