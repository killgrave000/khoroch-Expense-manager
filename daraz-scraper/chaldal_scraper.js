const axios = require('axios');

async function scrapeChaldalDeals(query = 'rice') {
  const url = `https://chaldal.com/rest/V1/search/products?q=${encodeURIComponent(query)}`;

  try {
    const res = await axios.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Accept': 'application/json',
      },
    });

    const products = res.data.products || [];

    const deals = products.map((p) => ({
      title: p.name,
      price: p.price,
      image: p.image,
      stock: p.stock,
      link: `https://chaldal.com${p.url}`,
    }));

    return deals;
  } catch (err) {
    console.error('❌ Failed to scrape Chaldal:', err.message);
    return [];
  }
}

module.exports = { scrapeChaldalDeals };
