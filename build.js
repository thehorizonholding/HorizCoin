const fs = require('fs');
const path = require('path');

// Create dist directory
const distDir = path.join(__dirname, 'dist');
if (!fs.existsSync(distDir)) {
  fs.mkdirSync(distDir);
}

// Generate the HTML content (matching the Rust server output)
const html = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HorizCoin</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 2rem;
            border-radius: 10px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
        }
        h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
            text-align: center;
        }
        .version {
            text-align: center;
            font-size: 1.2rem;
            opacity: 0.8;
            margin-bottom: 2rem;
        }
        .description {
            font-size: 1.1rem;
            line-height: 1.6;
            text-align: center;
        }
        .links {
            margin-top: 2rem;
            text-align: center;
        }
        .links a {
            color: #fff;
            text-decoration: none;
            padding: 0.5rem 1rem;
            border: 1px solid rgba(255, 255, 255, 0.3);
            border-radius: 5px;
            margin: 0 0.5rem;
            transition: all 0.3s ease;
        }
        .links a:hover {
            background: rgba(255, 255, 255, 0.2);
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🌅 HorizCoin</h1>
        <div class="version">Version 0.1.0</div>
        <div class="description">
            <p>A blockchain protocol implementing a Proof-of-Bandwidth consensus mechanism.</p>
            <p>This is a live demo instance of the HorizCoin web interface.</p>
        </div>
        <div class="links">
            <a href="https://github.com/thehorizonholding/HorizCoin" target="_blank">GitHub Repository</a>
            <a href="https://github.com/thehorizonholding/HorizCoin#quick-start" target="_blank">Documentation</a>
        </div>
    </div>
</body>
</html>`;

// Write the HTML file
fs.writeFileSync(path.join(distDir, 'index.html'), html);

console.log('Static build complete! Generated:', path.join(distDir, 'index.html'));