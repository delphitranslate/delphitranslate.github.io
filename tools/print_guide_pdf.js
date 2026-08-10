const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

async function main() {
  const [htmlFile, pdfFile, guideTitle] = process.argv.slice(2);
  if (!htmlFile || !pdfFile || !guideTitle) {
    throw new Error('Usage: print_guide_pdf.js <html> <pdf> <title>');
  }
  const browserCandidates = [
    process.env.DAT_BROWSER,
    'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
    'C:/Program Files/Google/Chrome/Application/chrome.exe'
  ].filter(candidate => candidate && fs.existsSync(candidate));
  if (browserCandidates.length === 0) {
    throw new Error('Microsoft Edge or Google Chrome was not found. Set DAT_BROWSER.');
  }
  const browser = await chromium.launch({
    headless: true,
    executablePath: browserCandidates[0]
  });
  try {
    const page = await browser.newPage();
    await page.goto('file:///' + path.resolve(htmlFile).replace(/\\/g, '/'), {
      waitUntil: 'load'
    });
    await page.pdf({
      path: path.resolve(pdfFile),
      format: 'Letter',
      printBackground: true,
      displayHeaderFooter: true,
      headerTemplate: `<div style="font-family:Arial,sans-serif;font-size:8px;color:#5d7693;width:100%;text-align:right;padding-right:0.7in;">${guideTitle}</div>`,
      footerTemplate: '<div style="font-family:Arial,sans-serif;font-size:8px;color:#5d7693;width:100%;text-align:center;"><span class="pageNumber"></span></div>',
      margin: { top: '0.72in', right: '0.82in', bottom: '0.72in', left: '0.82in' }
    });
  } finally {
    await browser.close();
  }
}

main().catch(error => {
  process.stderr.write(error.stack + '\n');
  process.exit(1);
});
