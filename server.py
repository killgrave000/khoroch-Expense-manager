from flask import Flask, request, jsonify
from flask_cors import CORS
from chaldal_selenium_scraper import scrape_chaldal_deals
from daraz_selenium_scraper import scrape_daraz_deals

app = Flask(__name__)
CORS(app)

@app.route('/api/deals', methods=['GET'])
def get_deals():
    query = request.args.get('q', 'rice')
    region = request.args.get('region', 'daraz')

    try:
        if region == 'chaldal':
            deals = scrape_chaldal_deals(query)
        elif region == 'daraz':
            deals = scrape_daraz_deals(query, 'bd')  # Default to Bangladesh
        else:
            return jsonify({'error': 'Unsupported region'}), 400

        return jsonify({'deals': deals})
    except Exception as e:
        return jsonify({'error': 'Scraping failed', 'details': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)
