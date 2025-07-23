const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const cors = require('cors');

const app = express();
app.use(cors()); // Enable CORS for all origins

// Helper to get the correct Daraz domain
function getDarazDomain(region) {
  const domains = {
    bd: 'daraz.com.bd',
    pk: 'daraz.pk',
    lk: 'daraz.lk',
    mm: 'daraz.com.mm',
    np: 'daraz.com.np'
  };
  return domains[region] || domains.bd;
}

// Route: /api/deals?q=laptop&region=bd
app.get('/api/deals', async (req, res) => {
  const query = req.query.q || 'discount';
  const region = req.query.region || 'bd';
  const domain = getDarazDomain(region);
  const url = `https://${domain}/catalog/?q=${encodeURIComponent(query)}`;

  try {
    const { data } = await axios.get(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'Referer': 'https://www.google.com'
      }
    });

    const $ = cheerio.load(data);
    const deals = [];

    // Updated selector logic based on Daraz HTML as of July 2025
    $('div[data-qa-locator="product-item"]').each((i, el) => {
      const anchor = $(el).find('a');
      const title = anchor.attr('title') || anchor.text().trim();
      const price = $(el).find('.price--NVB62').first().text().trim();
      const link = anchor.attr('href');
      const image = $(el).find('img').attr('src') || $(el).find('img').attr('data-src');

      if (title && price && link && image) {
        deals.push({
          title,
          price,
          link: link.startsWith('http') ? link : `https:${link}`,
          image: image.startsWith('http') ? image : `https:${image}`
        });
      }
    });

    res.json({ deals });
  } catch (error) {
    console.error('🔥 Error fetching Daraz page:', error.message);
    res.status(500).json({ error: 'Failed to fetch deals', details: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`✅ Scraper running at http://localhost:${PORT}/api/deals`);
});
