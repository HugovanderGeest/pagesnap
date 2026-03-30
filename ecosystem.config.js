module.exports = {
  apps: [
    {
      name: 'peruse',
      script: 'node_modules/next/dist/bin/next',
      args: 'start -p 3000', // or whatever port you need
      cwd: './',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production'
      }
    }
  ]
};
