#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { NotificationsStack } from '../lib/notifications-stack';

const app = new cdk.App();

new NotificationsStack(app, 'LoansNotificationsStack', {
  description: 'Pila serverless de notificaciones (SNS → SQS → Lambda → DynamoDB)',
  // En LocalStack la cuenta es 000000000000 y la región us-east-1 por defecto.
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
});
