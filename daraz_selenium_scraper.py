from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from webdriver_manager.chrome import ChromeDriverManager
import time

def get_daraz_domain(region):
    domains = {
        'bd': 'daraz.com.bd',
        'pk': 'daraz.pk',
        'lk': 'daraz.lk',
        'mm': 'daraz.com.mm',
        'np': 'daraz.com.np',
    }
    return domains.get(region, 'daraz.com.bd')

def scrape_daraz_deals(query='discount', region='bd'):
    domain = get_daraz_domain(region)
    url = f"https://{domain}/catalog/?q={query}"

    print(f"🔍 Scraping: {url}")

    # Chrome options
    chrome_options = Options()
    chrome_options.add_argument("--headless=new")  # Use old if needed
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")

    # Launch browser
    driver = webdriver.Chrome(service=Service(ChromeDriverManager().install()), options=chrome_options)
    driver.get(url)
    time.sleep(3)  # wait for JS to render

    deals = []
    try:
        cards = driver.find_elements(By.CSS_SELECTOR, 'div[data-qa-locator="product-item"]')

        for card in cards:
            try:
                title = card.find_element(By.TAG_NAME, 'img').get_attribute('alt')
                price_elem = card.find_element(By.CSS_SELECTOR, '.price--NVB62, .ooOxS')
                price = price_elem.text.strip() if price_elem else ''
                image = card.find_element(By.TAG_NAME, 'img').get_attribute('src')
                anchor = card.find_element(By.TAG_NAME, 'a')
                link = anchor.get_attribute('href')
                if not link.startswith('http'):
                    link = f"https:{link}"

                if title and price and image and link:
                    deals.append({
                        'title': title,
                        'price': price,
                        'image': image,
                        'link': link
                    })
            except Exception:
                continue

    finally:
        driver.quit()

    return deals
