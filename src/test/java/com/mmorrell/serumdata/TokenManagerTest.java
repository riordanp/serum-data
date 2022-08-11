package com.mmorrell.serumdata;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.mmorrell.serumdata.manager.TokenManager;
import lombok.extern.slf4j.Slf4j;
import okhttp3.OkHttpClient;
import org.junit.jupiter.api.Test;

import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.assertTrue;

@Slf4j
public class TokenManagerTest {

    private final TokenManager tokenManager;

    public TokenManagerTest() {
        this.tokenManager = new TokenManager(
                new OkHttpClient.Builder()
                        .callTimeout(10, TimeUnit.SECONDS)
                        .build(),
                new ObjectMapper()
        );
    }

    @Test
    public void constructorTest() {
        assertTrue(tokenManager.getPlaceHolderImage().length > 1);
    }
}
