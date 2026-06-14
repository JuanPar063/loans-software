# infra — Pila serverless de notificaciones (AWS CDK)

Infraestructura **como código** (AWS CDK, TypeScript) que define una rebanada **serverless** y
**event-driven** del sistema de préstamos:

```
loan-service ──publica──► SNS (LoanEvents) ──► SQS (NotificationsQueue) ──► Lambda ──► DynamoDB
                                                        └──(falla x3)──► DLQ
```

Cuando se aprueba un préstamo o se registra un pago, `loan-service` publica un evento en SNS; una
Lambda lo consume desde SQS, "envía" la notificación y la guarda en DynamoDB. Todo se puede ejecutar
**localmente con LocalStack** (sin cuenta AWS ni costos).

## Requisitos
- Node 18+ y Docker (LocalStack corre en Docker; ya está en `../docker-compose.yml`).
- Herramientas: `npm i -g aws-cdk-local awscli-local` (cdklocal + awslocal).

## Validar la IaC (sin desplegar)
```bash
npm install
npm run synth        # genera la plantilla CloudFormation (valida la infra)
```

## Desplegar en LocalStack (demo local)
```bash
# 1) Levanta LocalStack (desde la carpeta loans-software)
docker compose up -d localstack

# 2) Despliega la pila en LocalStack
cd infra
npm install
npm run deploy:local        # cdklocal bootstrap && cdklocal deploy

# 3) Verifica
awslocal sns list-topics
awslocal dynamodb scan --table-name Notifications
```

## Probar el flujo end-to-end
1. Con el stack desplegado y `loan-service` configurado (variables `LOAN_EVENTS_TOPIC_ARN` y
   `AWS_ENDPOINT_URL` en el compose), aprueba un préstamo o registra un pago desde la app.
2. `loan-service` publica el evento → SQS → Lambda → DynamoDB.
3. Comprueba la notificación persistida:
   ```bash
   awslocal dynamodb scan --table-name Notifications
   ```

## Desplegar a AWS real (opcional)
```bash
cdk bootstrap            # una vez por cuenta/región
cdk deploy
```
Lambda + SQS + SNS + DynamoDB caben en la capa gratuita.

## Estructura
- `bin/infra.ts` — entrypoint de la app CDK.
- `lib/notifications-stack.ts` — definición de la infraestructura (SNS, SQS+DLQ, Lambda, DynamoDB).
- `lambda/notification.js` — handler de la Lambda (Node, AWS SDK v3).
