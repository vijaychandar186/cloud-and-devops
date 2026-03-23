package com.lab13;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class AppTest {
    @Test
    void testGreet() {
        assertEquals("Hello, Lab 13!", App.greet("Lab 13"));
    }
}
