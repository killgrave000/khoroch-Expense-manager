const puppeteer = require('puppeteer');
const fs = require('fs');

async function scrapeShwapnoDeals(productPath = '/new-alu') {
  const url = `https://www.shwapno.com${productPath}`;
  console.log(`🍪 Loading cookies and scraping: ${url}`);

  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });

  try {
    const page = await browser.newPage();

    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36'
    );

    const cookies = JSON.parse(fs.readFileSync('./cookies.json', 'utf8'));
    await page.setCookie(...cookies);

    await page.goto(url, { waitUntil: 'networkidle2', timeout: 30000 });

    await page.screenshot({ path: 'shwapno_debug.png', fullPage: true });
    console.log('📸 Screenshot saved as shwapno_debug.png');

    const product = await page.evaluate(() => {
      const title = document.querySelector('h1')?.innerText || '';
      const price = document.querySelector('.price span')?.innerText || '';
      const unit = document.querySelector('.product-unit')?.innerText || '';
      const image = document.querySelector('img')?.src || '';

      return { title, price, unit, image, link: window.location.href };
    });

    console.log('✅ Scraped product:', product);
    await browser.close();
    return [product];
  } catch (err) {
    await browser.close();
    console.error('🔥 Scraper failed:', err.message);
    throw err;
  }
}

module.exports = { scrapeShwapnoDeals };
