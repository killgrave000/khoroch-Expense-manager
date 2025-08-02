const express = require('express');
const cors = require('cors');
const { scrapeDarazDeals } = require('./daraz-scraper/daraz_scraper');
const { scrapeChaldalDeals } = require('./daraz-scraper/chaldal_scraper');

const app = express();
app.use(cors());

app.get('/api/deals', async (req, res) => {
  const query = req.query.q?.trim() || 'discount';
  const region = req.query.region || 'bd';

  try {
    let deals = [];

    if (region === 'chaldal') {
      deals = await scrapeChaldalDeals(query);
    } else {
      deals = await scrapeDarazDeals(query, region);
    }

    if (deals.length === 0) {
      console.warn(`⚠️ No deals found for region: ${region}`);
    } else {
      console.log(`✅ ${deals.length} deals found for region: ${region}`);
    }

    res.json({ deals });
  } catch (error) {
    console.error(`🔥 Error scraping ${region}:`, error.message);
    res.status(500).json({
      error: `Failed to scrape ${region}`,
      details: error.message,
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server running at http://0.0.0.0:${PORT}/api/deals`);
});
