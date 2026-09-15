package dev.partur.task2;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

public class App {
    public static void main(String[] args) {
        Person original = new Person("El", "Gato", 20);

        Gson gson = new GsonBuilder().setPrettyPrinting().create();
        String json = gson.toJson(original);
        Person restored = gson.fromJson(json, Person.class);

        System.out.println("JSON:");
        System.out.println(json);
        System.out.println("Об'єкти рівні: " + original.equals(restored));
        System.out.println("Відновлений об'єкт: " + restored);
    }
}
