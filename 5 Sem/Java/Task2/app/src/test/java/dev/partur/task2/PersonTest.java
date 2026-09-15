package dev.partur.task2;

import com.google.gson.Gson;
import nl.jqno.equalsverifier.EqualsVerifier;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class PersonTest {
    @Test
    void equalsAndHashCodeMeetTheirContracts() {
        EqualsVerifier.forClass(Person.class).verify();
    }

    @Test
    void gsonPreservesPerson() {
        Person original = new Person("El", "Gato", 20);
        Gson gson = new Gson();

        String json = gson.toJson(original);
        Person restored = gson.fromJson(json, Person.class);

        assertEquals(original, restored);
    }
}
