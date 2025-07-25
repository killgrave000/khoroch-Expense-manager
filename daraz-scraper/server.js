const express = require('express');
const cors = require('cors');
const puppeteer = require('puppeteer');

const app = express();
app.use(cors()); // Allow all origins

// Supported Daraz domains by region
function getDarazDomain(region) {
  const domains = {
    bd: 'daraz.com.bd',
    pk: 'daraz.pk',
    lk: 'daraz.lk',
    mm: 'daraz.com.mm',
    np: 'daraz.com.np',
  };
  return domains[region] || domains.bd;
}

// Main deals endpoint
app.get('/api/deals', async (req, res) => {
  const query = req.query.q?.trim() || 'discount';
  const region = req.query.region || 'bd';
  const domain = getDarazDomain(region);
  const url = `https://${domain}/catalog/?q=${encodeURIComponent(query)}`;

  console.log(`🔍 Scraping: ${url}`);

  try {
    const browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox'],
    });

    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });

    // Scrape product cards from the rendered DOM
    const deals = await page.evaluate(() => {
      const items = document.querySelectorAll('div[data-qa-locator="product-item"]');
      const results = [];

      items.forEach(card => {
        const title = card.querySelector('img')?.alt || '';
        const price = card.querySelector('.price--NVB62, .ooOxS')?.textContent?.trim() || '';
        const image = card.querySelector('img')?.src || '';
        const anchor = card.querySelector('a');
        const link = anchor?.href?.startsWith('http') ? anchor.href : `https:${anchor?.getAttribute('href')}`;

        if (title && price && image && link) {
          results.push({ title, price, image, link });
        }
      });

      return results;
    });

    await browser.close();

    if (deals.length === 0) {
      console.warn('⚠️ No deals found. DOM may have changed.');
    } else {
      console.log(`✅ ${deals.length} deals found.`);
    }

    res.json({ deals });
  } catch (error) {
    console.error('🔥 Puppeteer scraping error:', error.message);
    res.status(500).json({
      error: 'Failed to scrape Daraz',
      details: error.message,
    });
  }
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Puppeteer server running at http://0.0.0.0:${PORT}/api/deals`);
});
