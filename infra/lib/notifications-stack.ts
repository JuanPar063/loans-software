import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as subs from 'aws-cdk-lib/aws-sns-subscriptions';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as dynamodb from 'aws-cdk-lib/aws-dynamodb';
import { SqsEventSource } from 'aws-cdk-lib/aws-lambda-event-sources';
import * as path from 'path';

/**
 * Pila serverless de notificaciones (event-driven):
 *
 *   loan-service ──publica──► SNS (LoanEvents)
 *                                  │  (fan-out)
 *                                  ▼
 *                             SQS (NotificationsQueue) ──(falla x3)──► DLQ
 *                                  │  (trigger)
 *                                  ▼
 *                             Lambda (notification-handler)
 *                                  │  "envía" la notificación
 *                                  ▼
 *                             DynamoDB (Notifications)
 *
 * Todo definido como Infraestructura como Código (CDK / TypeScript).
 */
export class NotificationsStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // 1) Tabla DynamoDB donde se persisten las notificaciones enviadas
    const table = new dynamodb.Table(this, 'NotificationsTable', {
      tableName: 'Notifications',
      partitionKey: { name: 'id', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.DESTROY, // demo: se borra al destruir la pila
    });

    // 2) Topic SNS: punto de publicación de eventos de negocio
    const topic = new sns.Topic(this, 'LoanEventsTopic', {
      topicName: 'LoanEvents',
      displayName: 'Eventos de préstamos',
    });

    // 3) Cola SQS + DLQ (buffer, reintentos y aislamiento de mensajes problemáticos)
    const dlq = new sqs.Queue(this, 'NotificationsDLQ', {
      queueName: 'NotificationsDLQ',
      retentionPeriod: cdk.Duration.days(14),
    });
    const queue = new sqs.Queue(this, 'NotificationsQueue', {
      queueName: 'NotificationsQueue',
      visibilityTimeout: cdk.Duration.seconds(60),
      deadLetterQueue: { queue: dlq, maxReceiveCount: 3 },
    });

    // 4) Fan-out: el topic entrega los eventos a la cola
    topic.addSubscription(new subs.SqsSubscription(queue));

    // 5) Lambda que consume la cola y procesa la notificación
    const fn = new lambda.Function(this, 'NotificationHandler', {
      functionName: 'notification-handler',
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'notification.handler',
      code: lambda.Code.fromAsset(path.join(__dirname, '..', 'lambda')),
      timeout: cdk.Duration.seconds(30),
      environment: {
        NOTIFICATIONS_TABLE: table.tableName,
      },
    });

    // 6) Trigger (SQS → Lambda) + permisos mínimos (escribir en la tabla)
    fn.addEventSource(new SqsEventSource(queue, { batchSize: 5 }));
    table.grantWriteData(fn);

    // Salidas útiles (para configurar loan-service y para verificar)
    new cdk.CfnOutput(this, 'TopicArn', { value: topic.topicArn });
    new cdk.CfnOutput(this, 'QueueUrl', { value: queue.queueUrl });
    new cdk.CfnOutput(this, 'TableName', { value: table.tableName });
  }
}
