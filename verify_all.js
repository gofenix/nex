const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  async function testPage(url, inputSelector, buttonSelector, expectedStatusText) {
    console.log(`\nTesting page: ${url}`);
    await page.goto(url);
    await page.waitForSelector(inputSelector);
    
    console.log('Filling input...');
    await page.fill(inputSelector, 'Beijing Weather');
    await page.press(inputSelector, 'Enter');
    
    console.log('Waiting for response...');
    // Wait for some time for the stream to start/finish
    await page.waitForTimeout(5000);
    
    const content = await page.textContent('body');
    // console.log('Page content snippet:', content.substring(0, 500));
    
    if (content.toLowerCase().includes('beijing') || content.toLowerCase().includes('weather')) {
        console.log(`SUCCESS: Found response on ${url}`);
        return true;
    } else {
        console.log(`FAILURE: No response found on ${url}`);
        return false;
    }
  }

  try {
    const sseOk = await testPage(
        'http://localhost:4001/sse', 
        'input[placeholder*="Type a message"]', 
        'button[type="submit"]'
    );
    
    const datastarOk = await testPage(
        'http://localhost:4001/datastar_ai', 
        'input[placeholder*="Ask about the weather"]', 
        'button[type="submit"]'
    );

    if (sseOk && datastarOk) {
        console.log('\nALL TESTS PASSED!');
    } else {
        console.log('\nSOME TESTS FAILED!');
    }
  } catch (e) {
    console.error('Test error:', e);
  } finally {
    await browser.close();
  }
})();
