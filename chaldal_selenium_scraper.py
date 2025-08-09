from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
import time

def scrape_chaldal_deals(query='rice'):
    options = Options()
    options.add_argument("--headless=new")  # Use new headless for Chrome v109+
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    driver = webdriver.Chrome(options=options)

    search_url = f"https://chaldal.com/search/{query}"
    driver.get(search_url)
    time.sleep(5)  # Wait for JS to load products

    results = []
    products = driver.find_elements(By.CSS_SELECTOR, 'div.product')

    for p in products:
        try:
            title = p.find_element(By.CSS_SELECTOR, '.name').text
            price = p.find_element(By.CSS_SELECTOR, '.price').text
            image = p.find_element(By.CSS_SELECTOR, 'img').get_attribute('src')
            link = p.find_element(By.TAG_NAME, 'a').get_attribute('href')
            results.append({
                'title': title,
                'price': price,
                'image': image,
                'link': link,
            })
        except Exception:
            continue

    driver.quit()
    return results
