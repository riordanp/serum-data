package com.mmorrell.serumdata.controller;

import com.mmorrell.serumdata.client.MangoClient;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.p2p.solanaj.core.PublicKey;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.io.IOException;
import java.util.Optional;

@RestController
@Slf4j
public class MangoController {

    private final MangoClient mangoClient;

    public MangoController(final MangoClient mangoClient) {
        this.mangoClient = mangoClient;
    }

    @GetMapping(value = "/mango/lookup/{ooa}")
    public void mangoOoaLookupRedirect(@PathVariable String ooa, HttpServletResponse response) throws IOException {
        PublicKey ooaPubkey = new PublicKey(ooa);
        final Optional<PublicKey> mangoAccountPubkey = mangoClient.getMangoAccountFromOoa(ooaPubkey);

        if (mangoAccountPubkey.isPresent()) {
            final String mangoUrl = String.format(
                    "https://trade.mango.markets/account?pubkey=%s&ref=openserum",
                    mangoAccountPubkey.get().toBase58()
            );
            response.sendRedirect(mangoUrl);
        } else {
            response.sendRedirect("https://trade.mango.markets/?ref=openserum");
        }
    }
}
