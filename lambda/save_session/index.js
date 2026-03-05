// index.js

const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");

// 기본 클라이언트 생성
const client = new DynamoDBClient({});
const ddb = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  console.log("Received event:", event);

  const tableName = process.env.TABLE_NAME;

  // Unreal에서 들어오는 값이 string일 수도 있음
  const body = typeof event.body === "string" ? JSON.parse(event.body) : event;

  const {
    StudentID,
    SessionID,
    StudentName,
    ScenarioCharacterName,
    ScenarioNumber,
    Progress,
    CompletionTime,
    Logs
  } = body;

  try {
    const params = {
      TableName: tableName,
      Item: {
        StudentID,
        SessionID,
        StudentName: StudentName ?? "Unknown",
        ScenarioCharacterName: ScenarioCharacterName ?? "Unknown",
        ScenarioNumber: ScenarioNumber ?? 0,
        Progress: Progress ?? 0,
        CompletionTime: CompletionTime ?? "",
        Logs: Logs ?? [],
        LastUpdated: Date.now()
      }
    };

    console.log("Saving to DynamoDB:", params);

    await ddb.send(new PutCommand(params));

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: "Save successful",
        saved: params.Item
      })
    };

  } catch (err) {
    console.error("DynamoDB error:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: "Failed to save",
        details: err.message
      })
    };
  }
};
