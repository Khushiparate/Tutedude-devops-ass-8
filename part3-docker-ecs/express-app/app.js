const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send('Express Frontend - ECS Fargate - Part 3!');
});

app.listen(3000, '0.0.0.0', () => {
  console.log('Express on port 3000');
});
