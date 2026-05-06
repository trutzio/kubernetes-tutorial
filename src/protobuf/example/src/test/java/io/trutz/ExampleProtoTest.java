package io.trutz;

import java.io.FileOutputStream;
import java.io.IOException;

import org.junit.jupiter.api.Test;

import io.trutz.ExampleProto.Person;

class ExampleProtoTest {

    @Test
    void testExampleProto() throws IOException {
        Person john = Person.newBuilder()
                .setId(1234)
                .setName("John Doe")
                .setEmail("jdoe@example.com")
                .build();
        var output = new FileOutputStream("john.bin");
        john.writeTo(output);
        output.close();
    }

}
