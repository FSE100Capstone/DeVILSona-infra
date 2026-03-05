// lambda/login/index.js

const { DynamoDBClient, QueryCommand } = require("@aws-sdk/client-dynamodb");

// Lambda 환경에서 자동으로 AWS_REGION 이 들어옴
const REGION = process.env.AWS_REGION || "us-east-2";
const TABLE_NAME = process.env.TABLE_NAME || "StudentSessions";

const ddbClient = new DynamoDBClient({ region: REGION });

exports.handler = async (event) => {
  console.log("=== Login request ===");
  console.log(JSON.stringify(event, null, 2));

  // 1) 바디 파싱
  let body = null;
  try {
    if (event.body) {
      // API Gateway HTTP API에서 보통 body는 string
      body = JSON.parse(event.body);
    } else if (typeof event === "object") {
      // Lambda 콘솔에서 직접 테스트할 때 대비
      body = event;
    }
  } catch (e) {
    console.error("JSON parse error:", e);
  }

  if (!body || body.StudentID === undefined || !body.SessionID) {
    return {
      statusCode: 400,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "OPTIONS,POST"
      },
      body: JSON.stringify({
        ok: false,
        message: "StudentID and SessionID are required"
      })
    };
  }

  const studentId = Number(body.StudentID);
  const sessionId = String(body.SessionID);

  // low-level SDK 스타일: AttributeValue 형식 사용
  const params = {
    TableName: TABLE_NAME,
    KeyConditionExpression: "StudentID = :sid AND SessionID = :sess",
    ExpressionAttributeValues: {
      ":sid":  { N: String(studentId) },
      ":sess": { S: sessionId }
    }
  };

  console.log("DynamoDB Query params:", JSON.stringify(params));

  try {
    const result = await ddbClient.send(new QueryCommand(params));

    console.log("DynamoDB Query result:", JSON.stringify(result));

    const items = (result.Items || []).map((i) => ({
      StudentID: Number(i.StudentID.N),
      SessionKey: i.SessionKey?.S ?? i.SessionID?.S ?? "", // SessionKey 없으면 SessionID라도 사용
      StudentName: i.StudentName?.S ?? "",
      SessionID: i.SessionID?.S ?? "",
      ScenarioCharacterName: i.ScenarioCharacterName?.S ?? "",
      ScenarioNumber: i.ScenarioNumber ? Number(i.ScenarioNumber.N) : 0,
      Progress: i.Progress ? Number(i.Progress.N) : 0,
      CompletionTime: i.CompletionTime?.S ?? ""
    }));

    const exists = items.length > 0;

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "OPTIONS,POST"
      },
      body: JSON.stringify({
        ok: true,
        exists,
        sessions: items
      })
    };
  } catch (err) {
    console.error("DynamoDB Query error:", err);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "*",
        "Access-Control-Allow-Methods": "OPTIONS,POST"
      },
      body: JSON.stringify({
        ok: false,
        message: "Failed to query sessions",
        error: String(err)
      })
    };
  }
};
