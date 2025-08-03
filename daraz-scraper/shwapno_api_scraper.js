const axios = require('axios');

const headers = {
  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36',
  'Accept': 'application/json',
  'Origin': 'https://www.shwapno.com',
  'Referer': 'https://www.shwapno.com/',
  'Content-Type': 'application/json',
  'Cookie': '_clck=1g22krt%7C2%7Cftj%7C0%7C1875; _ga=GA1.2.1316467173.1739896142; _ga_3R50MQ1P3H=GS1.1.1739896141.1.0.1739896145.56.0.0; _muid=81849d60-ea2d-4515-a22e-37359674ec48; mtagId=null; isMarktagClientSide=false; mtag-consent=true; _cdlat_=23.7328895; _cdlng_=90.41924255; _ccl_=Motijheel%2C%20Motijheel%2C%20Dhaka; _nc_=false; _mo_=true; cuid=acdb86b6-5a5a-41a6-b8a7-793cf54f9ef8; _ds_=65eb62a4452e887cd78e256b'
};

async function fetchShwapnoDeals(query = 'alu') {
  try {
    const searchUrl = `https://www.shwapno.com/api/search/filter?q=${encodeURIComponent(query)}&limit=10`;

    const searchRes = await axios.get(searchUrl, { headers });
    const products = searchRes.data || [];

    if (!Array.isArray(products)) {
      console.warn('⚠️ Unexpected search response structure.');
      return [];
    }

    const results = [];

    for (const product of products) {
      const productId = product.productId || product.id;
      if (!productId) continue;

      const detailRes = await axios.post(
        'https://www.shwapno.com/api/product',
        { productId }, // POST payload
        { headers }
      );

      const data = detailRes.data;

      results.push({
        title: data.picture?.title || 'Unknown',
        price: data.price?.price || '',
        priceValue: data.price?.priceValue || '',
        oldPrice: data.price?.oldPrice || '',
        stock: data.stockAvailability || '',
        image: data.picture?.largeDeviceUrl?.imageUrl || '',
        unit: data.unit || '',
        link: `https://www.shwapno.com/product/${data.productId}`,
      });
    }

    return results;
  } catch (err) {
    console.error('🔥 Shwapno API failed:', err.message);
    return [];
  }
}

module.exports = { fetchShwapnoDeals };
