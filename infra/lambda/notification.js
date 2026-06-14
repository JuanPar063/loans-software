'use strict';
// Lambda de notificaciones. Consume mensajes de SQS (provenientes de SNS),
// "envía" la notificación (aquí: log; en producción sería SES/SMS/push) y la
// persiste en DynamoDB. Usa el AWS SDK v3 incluido en el runtime Node 20.
const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');
const { randomUUID } = require('crypto');

const ddb = new DynamoDBClient({});
const TABLE = process.env.NOTIFICATIONS_TABLE || 'Notifications';

function buildMessage(p) {
  switch (p.type) {
    case 'LoanApproved':
      return `Tu préstamo ${p.loanId} fue APROBADO.`;
    case 'PaymentRegistered':
      return `Pago de ${p.amount} registrado en el préstamo ${p.loanId}. Nuevo saldo: ${p.remainingBalance ?? 'N/D'}.`;
    default:
      return `Evento ${p.type || 'desconocido'}`;
  }
}

exports.handler = async (event) => {
  const records = event.Records || [];
  for (const record of records) {
    // SQS envuelve el mensaje; si viene de SNS el cuerpo trae { Message: "..." }
    let payload;
    try {
      const body = JSON.parse(record.body);
      payload = body.Message ? JSON.parse(body.Message) : body;
    } catch (e) {
      payload = { type: 'UNKNOWN', raw: record.body };
    }

    const message = buildMessage(payload);
    console.log(`📣 Notificación: ${message}`);

    await ddb.send(
      new PutItemCommand({
        TableName: TABLE,
        Item: {
          id: { S: randomUUID() },
          type: { S: String(payload.type || 'UNKNOWN') },
          userId: { S: String(payload.userId || 'N/A') },
          loanId: { S: String(payload.loanId || 'N/A') },
          message: { S: message },
          payload: { S: JSON.stringify(payload) },
          createdAt: { S: new Date().toISOString() },
        },
      }),
    );
  }

  return { processed: records.length };
};
