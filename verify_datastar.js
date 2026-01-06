const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  console.log('Navigating to Datastar AI page...');
  await page.goto('http://localhost:4001/datastar_ai');
  
  // Wait for the page to load
  await page.waitForSelector('input[placeholder="Ask about the weather..."]');
  
  console.log('Sending message...');
  await page.fill('input[placeholder="Ask about the weather..."]', 'Hello, how is the weather?');
  await page.press('input[placeholder="Ask about the weather..."]', 'Enter');
  
  console.log('Waiting for AI response...');
  // Check if isLoading signal is set (via attribute or just wait)
  // Datastar doesn't necessarily show signals in the DOM unless bound.
  // Our button has data-attr:disabled="$isLoading"
  
  // Wait for the AI message bubble to appear
  await page.waitForSelector('#messages-box .chat-bubble');
  
  // Wait for the status to change from "Thinking..." to something else or just wait for text
  // The content is in a p tag with data-text="$aiResponse"
  
  // Let's wait for the status signal to show "Ready"
  // We can check the text of the status span
  const statusSelector = 'span[data-text="$aiStatus"]';
  await page.waitForFunction(
    selector => document.querySelector(selector)?.innerText.includes('Ready'),
    statusSelector,
    { timeout: 10000 }
  );
  
  const content = await page.textContent('#messages-box');
  console.log('Chat Box Content:', content);
  
  if (content.includes('Mock response')) {
    console.log('SUCCESS: AI response found!');
  } else {
    console.log('FAILURE: AI response not found or empty.');
    // Check if the response disappeared
    const aiResponseText = await page.evaluate(() => {
        return document.querySelector('p[data-text="$aiResponse"]')?.innerText;
    });
    console.log('aiResponse signal text:', aiResponseText);
  }

  await browser.close();
})();
