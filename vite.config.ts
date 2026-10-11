import react from '@vitejs/plugin-react'
import { defineConfig, type Plugin } from 'vite'
import { handleCollectPrices } from './src/server/collectorHandler.ts'

function collectPricesDevPlugin(): Plugin {
  return {
    name: 'collect-prices-dev-server',
    configureServer(server) {
      server.middlewares.use(async (req, res, next) => {
        const url = req.url?.split('?')[0];
        if (req.method === 'POST' && (url === '/api/collect-prices' || url?.startsWith('/functions/v1/collect-prices'))) {
          let bodyStr = '';
          req.on('data', chunk => { bodyStr += chunk; });
          req.on('end', async () => {
            try {
              const body = bodyStr ? JSON.parse(bodyStr) : {};
              const result = await handleCollectPrices(body);
              res.setHeader('Content-Type', 'application/json');
              res.setHeader('Access-Control-Allow-Origin', '*');
              res.statusCode = 200;
              res.end(JSON.stringify(result));
            } catch (err: any) {
              res.statusCode = 500;
              res.setHeader('Content-Type', 'application/json');
              res.end(JSON.stringify({ error: err.message || 'Internal error' }));
            }
          });
          return;
        }

        if (req.method === 'OPTIONS' && (url === '/api/collect-prices' || url?.startsWith('/functions/v1/collect-prices'))) {
          res.setHeader('Access-Control-Allow-Origin', '*');
          res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
          res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
          res.statusCode = 204;
          res.end();
          return;
        }

        next();
      });
    }
  };
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), collectPricesDevPlugin()],
})
