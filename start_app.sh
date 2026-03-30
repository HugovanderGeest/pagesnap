#!/bin/bash
npm install
npm run build
pm2 stop peruse || true
pm2 start ecosystem.config.js
pm2 save
