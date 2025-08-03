const puppeteer = require('puppeteer');

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

async function scrapeDarazDeals(query = 'discount', region = 'bd') {
  const domain = getDarazDomain(region);
  const url = `https://${domain}/catalog/?q=${encodeURIComponent(query)}`;

  console.log(`🔍 Scraping: ${url}`);

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  try {
    const page = await browser.newPage();
    await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });

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
    return deals;
  } catch (error) {
    await browser.close();
    throw error;
  }
}

module.exports = { scrapeDarazDeals };
