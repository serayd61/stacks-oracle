/**
 * Stacks Oracle Reporter
 * Fetches prices from external sources and submits to the oracle contract
 */

const PRICE_SOURCES = {
  'STX-USD': [
    'https://api.coingecko.com/api/v3/simple/price?ids=blockstack&vs_currencies=usd',
    'https://api.binance.com/api/v3/ticker/price?symbol=STXUSDT',
  ],
  'BTC-USD': [
    'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd',
    'https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT',
  ],
  'ETH-USD': [
    'https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd',
    'https://api.binance.com/api/v3/ticker/price?symbol=ETHUSDT',
  ],
};

const UPDATE_INTERVAL = 10 * 60 * 1000; // 10 minutes

/**
 * Fetch price from CoinGecko
 */
async function fetchCoinGeckoPrice(coinId) {
  try {
    const response = await fetch(
      `https://api.coingecko.com/api/v3/simple/price?ids=${coinId}&vs_currencies=usd`
    );
    const data = await response.json();
    return data[coinId]?.usd || null;
  } catch (error) {
    console.error(`CoinGecko error for ${coinId}:`, error.message);
    return null;
  }
}

/**
 * Fetch price from Binance
 */
async function fetchBinancePrice(symbol) {
  try {
    const response = await fetch(
      `https://api.binance.com/api/v3/ticker/price?symbol=${symbol}`
    );
    const data = await response.json();
    return parseFloat(data.price) || null;
  } catch (error) {
    console.error(`Binance error for ${symbol}:`, error.message);
    return null;
  }
}

/**
 * Get aggregated price from multiple sources
 */
async function getAggregatedPrice(pair) {
  const prices = [];
  
  if (pair === 'STX-USD') {
    const cg = await fetchCoinGeckoPrice('blockstack');
    const bn = await fetchBinancePrice('STXUSDT');
    if (cg) prices.push(cg);
    if (bn) prices.push(bn);
  } else if (pair === 'BTC-USD') {
    const cg = await fetchCoinGeckoPrice('bitcoin');
    const bn = await fetchBinancePrice('BTCUSDT');
    if (cg) prices.push(cg);
    if (bn) prices.push(bn);
  } else if (pair === 'ETH-USD') {
    const cg = await fetchCoinGeckoPrice('ethereum');
    const bn = await fetchBinancePrice('ETHUSDT');
    if (cg) prices.push(cg);
    if (bn) prices.push(bn);
  }
  
  if (prices.length === 0) return null;
  
  // Calculate median
  prices.sort((a, b) => a - b);
  const mid = Math.floor(prices.length / 2);
  return prices.length % 2 !== 0
    ? prices[mid]
    : (prices[mid - 1] + prices[mid]) / 2;
}

/**
 * Convert price to micro units (6 decimals)
 */
function priceToMicro(price) {
  return Math.round(price * 1_000_000);
}

/**
 * Submit price to oracle contract
 */
async function submitPrice(pair, price) {
  const microPrice = priceToMicro(price);
  const timestamp = Math.floor(Date.now() / 1000);
  
  console.log(`Submitting ${pair}: $${price} (${microPrice} micro)`);
  
  // In production, this would call the Stacks contract
  // Using @stacks/transactions library
  
  /*
  const txOptions = {
    contractAddress: 'SP...',
    contractName: 'oracle-core',
    functionName: 'submit-price',
    functionArgs: [
      stringAsciiCV(pair),
      uintCV(microPrice),
      uintCV(timestamp),
    ],
    senderKey: REPORTER_PRIVATE_KEY,
    network: new StacksMainnet(),
    postConditionMode: PostConditionMode.Allow,
    fee: 1000n,
  };
  
  const tx = await makeContractCall(txOptions);
  const result = await broadcastTransaction(tx);
  */
  
  return { pair, price: microPrice, timestamp };
}

/**
 * Main reporter loop
 */
async function runReporter() {
  console.log('🔮 Stacks Oracle Reporter Started');
  console.log(`Update interval: ${UPDATE_INTERVAL / 1000}s`);
  
  const pairs = ['STX-USD', 'BTC-USD', 'ETH-USD'];
  
  while (true) {
    console.log('\n--- Price Update Round ---');
    console.log(`Time: ${new Date().toISOString()}`);
    
    for (const pair of pairs) {
      try {
        const price = await getAggregatedPrice(pair);
        if (price) {
          await submitPrice(pair, price);
        } else {
          console.log(`No price available for ${pair}`);
        }
      } catch (error) {
        console.error(`Error updating ${pair}:`, error.message);
      }
    }
    
    console.log(`\nNext update in ${UPDATE_INTERVAL / 1000}s...`);
    await new Promise(resolve => setTimeout(resolve, UPDATE_INTERVAL));
  }
}

// Run if called directly
if (require.main === module) {
  runReporter().catch(console.error);
}

module.exports = {
  fetchCoinGeckoPrice,
  fetchBinancePrice,
  getAggregatedPrice,
  priceToMicro,
  submitPrice,
};

