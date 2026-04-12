import swaggerJsdoc from 'swagger-jsdoc';
import swaggerUi from 'swagger-ui-express';
import { Express } from 'express';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'mug-gohan API',
      version: '1.0.0',
      description: 'Self-Hosted Kochbuch API mit KI-Assistenz',
    },
  },
  apis: ['./src/routes/*.ts'],
};

const spec = swaggerJsdoc(options);

export function setupSwagger(app: Express): void {
  app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(spec));
}
