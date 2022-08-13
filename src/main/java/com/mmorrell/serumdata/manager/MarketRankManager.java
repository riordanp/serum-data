package com.mmorrell.serumdata.manager;

import com.mmorrell.serum.model.Market;
import com.mmorrell.serum.model.SerumUtils;
import com.mmorrell.serumdata.model.MarketListing;
import com.mmorrell.serumdata.model.Token;
import com.mmorrell.serumdata.util.MarketUtil;
import lombok.extern.slf4j.Slf4j;
import org.p2p.solanaj.core.PublicKey;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

@Component
@Slf4j
public class MarketRankManager {

    // Top tokens list, for quicker resolution from symbol.
    private static final Map<String, Token> TOP_TOKENS = Map.of(
            "SOL", Token.builder()
                    .publicKey(SerumUtils.WRAPPED_SOL_MINT)
                    .address(SerumUtils.WRAPPED_SOL_MINT.toBase58())
                    .build(),
            "USDC", Token.builder()
                    .publicKey(MarketUtil.USDC_MINT)
                    .address(MarketUtil.USDC_MINT.toBase58())
                    .build(),
            "USDT", Token.builder()
                    .publicKey(MarketUtil.USDT_MINT)
                    .address(MarketUtil.USDT_MINT.toBase58())
                    .build()
    );

    private final MarketManager marketManager;
    private final TokenManager tokenManager;
    private List<MarketListing> marketListings;
    private final Map<PublicKey, Integer> marketRankMap = new HashMap<>();

    public MarketRankManager(MarketManager marketManager, TokenManager tokenManager) {
        this.marketManager = marketManager;
        this.tokenManager = tokenManager;

        updateCachedMarketListings();

        log.info("Caching token images.");
        tokenManager.cacheAllTokenImages(
                marketListings.stream()
                        .map(MarketListing::getBaseMint)
                        .toList()
        );
        log.info("Successfully cached token images: " + marketListings.size());
    }

    @Scheduled(initialDelay = 5L, fixedRate = 5L, timeUnit = TimeUnit.MINUTES)
    public void updateMarketsScheduled() {
        marketManager.updateMarkets();
        updateCachedMarketListings();
    }

    // Used in Thymeleaf. Needs better solution.
    public String getImage(String tokenMint) {
        return "/api/serum/token/" + tokenMint + "/icon";
    }

    public Optional<Market> getMostActiveMarket(PublicKey baseMint) {
        List<Market> markets = marketManager.getMarketsByBaseMint(baseMint);
        if (markets.size() < 1) {
            return Optional.empty();
        }

        // sort by base deposits
        markets.sort(Comparator.comparingLong(Market::getBaseDepositsTotal).reversed());

        // prefer USDC over other pairs if 2 top pairs are XYZ / USDC
        if (markets.size() > 1) {
            Market firstMarket = markets.get(0);
            Market secondMarket = markets.get(1);

            // if first pair isn't USDC quoted, and second pair is, move it to first place
            if (!firstMarket.getQuoteMint().equals(MarketUtil.USDC_MINT) &&
                    secondMarket.getQuoteMint().equals(MarketUtil.USDC_MINT)) {
                markets.set(0, secondMarket);
                markets.set(1, firstMarket);
            }
        }

        return Optional.ofNullable(markets.get(0));
    }

    public Optional<Market> getMostActiveMarket(PublicKey baseMint, PublicKey quoteMint) {
        List<Market> markets = marketManager.getMarketsByTokenMint(baseMint);
        if (markets.size() < 1) {
            return Optional.empty();
        }

        // sort by base deposits
        markets.sort(Comparator.comparingLong(Market::getBaseDepositsTotal).reversed());
        for (Market market : markets) {
            if (market.getQuoteMint().equals(quoteMint)) {
                return Optional.of(market);
            }
        }

        return Optional.empty();
    }

    /**
     * Returns lightweight token (address only) if given symbol has an active serum market.
     *
     * @param symbol e.g. SOL or USDC or RAY
     * @return most active token for given symbol
     */
    public Optional<Token> getMostSerumActiveTokenBySymbol(String symbol) {
        if (TOP_TOKENS.containsKey(symbol)) {
            return Optional.of(TOP_TOKENS.get(symbol));
        }

        List<Token> possibleBaseTokens = tokenManager.getTokensBySymbol(symbol);
        List<Market> activeMarkets = new ArrayList<>();

        for (Token baseToken : possibleBaseTokens) {
            // compile list of markets, return one with most fees accrued.
            Optional<Market> optionalMarket = getMostActiveMarket(baseToken.getPublicKey());
            optionalMarket.ifPresent(activeMarkets::add);
        }
        activeMarkets.sort(Comparator.comparingLong(Market::getQuoteFeesAccrued).reversed());

        if (activeMarkets.size() > 0) {
            return tokenManager.getTokenByMint(activeMarkets.get(0).getBaseMint());
        } else {
            return Optional.empty();
        }
    }

    public List<MarketListing> getMarketListings() {
        return marketListings;
    }

    private void updateCachedMarketListings() {
        marketListings = marketManager.getMarketCache().stream()
                .map(market -> {
                    // base and quote decimals
                    Optional<Token> baseToken = tokenManager.getTokenByMint(market.getBaseMint());
                    Optional<Token> quoteToken = tokenManager.getTokenByMint(market.getQuoteMint());

                    int baseDecimals = 0, quoteDecimals = 0;
                    if (baseToken.isPresent()) {
                        baseDecimals = baseToken.get().getDecimals();
                    }

                    if (quoteToken.isPresent()) {
                        quoteDecimals = quoteToken.get().getDecimals();
                    }

                    PublicKey baseMint = baseToken.map(Token::getPublicKey).orElse(null);

                    PublicKey quoteMint = quoteToken.map(Token::getPublicKey).orElse(null);

                    return new MarketListing(
                            tokenManager.getMarketNameByMarket(market),
                            market.getOwnAddress(),
                            market.getQuoteDepositsTotal(),
                            marketManager.getQuoteNotional(market, quoteDecimals),
                            baseDecimals,
                            quoteDecimals,
                            baseMint,
                            quoteMint
                    );
                })
                .sorted((o1, o2) -> (int) (o2.getQuoteNotional() - o1.getQuoteNotional()))
                .toList();

        // update sorted token map
        if (marketListings.size() > 0) {
            for (int i = 0; i < marketListings.size(); i++) {
                MarketListing listing = marketListings.get(i);
                PublicKey baseMint = listing.getBaseMint();
                if (marketRankMap.containsKey(baseMint)) {
                    // lower rank is better: 1, 2, 3, etc
                    // only update if it's better (don't give a lowly-sorted market for a good coin a bad rank)
                    int rank = marketRankMap.get(baseMint);
                    if (i < rank) {
                        marketRankMap.put(baseMint, i + 1);
                    }

                } else {
                    marketRankMap.put(baseMint, i + 1);
                }
            }
        }
    }

    // used in thymeleaf
    public String getMarketListingName(MarketListing market) {
        String name = market.getName();
        if (name.startsWith(" -")) {
            name = name.replaceFirst(" -", "? -");
        }
        return name;
    }

    public int getRankByToken(PublicKey baseMint) {
        return marketRankMap.getOrDefault(baseMint, 99999);
    }
}
