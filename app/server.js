const express = require('express');
const os = require('os');
const app = express();

const port = process.env.PORT || 8080;
const version = process.env.APP_VERSION || 'v1';
const failHealthCheck = process.env.FAIL_HEALTH_CHECK === 'true';

app.get('/', (req, res) => {
  const hostname = os.hostname();
  const status = failHealthCheck ? 'Unhealthy' : 'Healthy';
  
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Zero-Downtime CI/CD Deployment</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f4f4f9; color: #333; }
        .container { background: #fff; padding: 30px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); max-width: 600px; margin: auto; }
        h1 { color: #0056b3; }
        .info { font-size: 1.2em; margin: 10px 0; }
        .status { font-weight: bold; color: ${failHealthCheck ? 'red' : 'green'}; }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>Zero-Downtime CI/CD Deployment</h1>
        <div class="info">Status: <span class="status">${status}</span></div>
        <div class="info">Application Version: <strong>${version}</strong></div>
        <div class="info">Serving Pod: <strong>${hostname}</strong></div>
      </div>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  if (failHealthCheck) {
    res.status(500).send('Internal Server Error (Simulated)');
  } else {
    res.status(200).send('OK');
  }
});

app.listen(port, () => {
  console.log(`Application version ${version} running on port ${port}`);
});
