import express from 'express';

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

// Placeholder epoch route
app.get('/epochs/latest', (_req, res) => {
  res.json({
    epoch: 1,
    reportRoot: '0xDEADBEEF',
    note: 'Placeholder data'
  });
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Backend API listening on :${port}`);
});
