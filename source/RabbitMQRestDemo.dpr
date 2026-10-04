program RabbitMQRestDemo;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
  IdHTTP;

const
  // Adjust these settings to match your local or test RabbitMQ server
  RABBITMQ_HOST     = 'localhost';
  RABBITMQ_PORT     = '15672'; // Management plugin HTTP port
  RABBITMQ_USER     = 'guest';
  RABBITMQ_PASS     = 'guest';
  RABBITMQ_VHOST    = '%2F';   // Default vhost '/' must be URL-encoded as '%2F'
  TARGET_EXCHANGE   = 'amq.direct';
  TARGET_QUEUE      = 'test-queue';
  ROUTING_KEY       = 'test-routing-key';

/// <summary>
/// Publishes a message via the RabbitMQ HTTP REST API
/// </summary>
procedure PublishViaRabbitMQREST(const AMessage: string);
var
  IdHTTP: TIdHTTP;
  JSON: TStringBuilder;
  RequestBody: TStream;
  ResponseBody: string;
  TargetURL: string;
begin
  IdHTTP := TIdHTTP.Create;
  JSON := TStringBuilder.Create;
  try
    // Construct JSON payload
    JSON.Append('{');
    JSON.Append('"properties": {},');
    JSON.Append('"routing_key": "' + ROUTING_KEY + '",');
    JSON.Append('"payload": "' + AMessage + '",');
    JSON.Append('"payload_encoding": "string"');
    JSON.Append('}');

    RequestBody := TStringStream.Create(JSON.ToString, TEncoding.UTF8);
    try
      IdHTTP.Request.BasicAuthentication := True;
      IdHTTP.Request.Username := RABBITMQ_USER;
      IdHTTP.Request.Password := RABBITMQ_PASS;
      IdHTTP.Request.ContentType := 'application/json';

      TargetURL := Format('http://%s:%s/api/exchanges/%s/%s/publish',
        [RABBITMQ_HOST, RABBITMQ_PORT, RABBITMQ_VHOST, TARGET_EXCHANGE]);

      Writeln('Sending message via HTTP POST...');
      ResponseBody := IdHTTP.Post(TargetURL, RequestBody);
      Writeln('Publish Response: ' + ResponseBody);
    finally
      RequestBody.Free;
    end;
  finally
    JSON.Free;
    IdHTTP.Free;
  end;
end;

/// <summary>
/// Fetches a single message via the RabbitMQ HTTP REST API
/// </summary>
procedure FetchViaRabbitMQREST;
var
  IdHTTP: TIdHTTP;
  JSON: TStringBuilder;
  RequestBody: TStringStream;
  Response: string;
  TargetURL: string;
begin
  IdHTTP := TIdHTTP.Create;

  try
    IdHTTP.Request.BasicAuthentication := True;
    IdHTTP.Request.Username := RABBITMQ_USER;
    IdHTTP.Request.Password := RABBITMQ_PASS;
    IdHTTP.Request.ContentType := 'application/json';

    // Construct configuration JSON for fetching
    JSON := TStringBuilder.Create;
    try
      JSON.Append('{');
      JSON.Append('  "vhost": "/",');
      JSON.Append('  "name": "' + TARGET_QUEUE + '",');
      JSON.Append('  "count": "1",');
      JSON.Append('  "ackmode": "ack_requeue_false",');
      JSON.Append('  "encoding": "auto"');
      JSON.Append('}');
      RequestBody := TStringStream.Create(JSON.ToString, TEncoding.UTF8);
      try
        TargetURL := Format('http://%s:%s/api/queues/%s/%s/get',
          [RABBITMQ_HOST, RABBITMQ_PORT, RABBITMQ_VHOST, TARGET_QUEUE]);

        Writeln('Fetching message via HTTP POST...');
        Response := IdHTTP.Post(TargetURL, RequestBody);
        if Response = '[]' then
          Writeln('Fetch Response: [Queue is empty]')
        else
          Writeln('Fetch Response: ' + Response);
      finally
        RequestBody.Free;
      end;
    finally
      JSON.Free;
    end;
  finally
    IdHTTP.Free;
  end;
end;

begin
  // ReportMemoryLeaksOnShutdown := True;

  try
    Writeln('==================================================');
    Writeln('  Delphi RabbitMQ REST API Starter Project Demo   ');
    Writeln('==================================================');
    Writeln;
    Writeln('Prerequisite: Ensure RabbitMQ Management Plugin is active.');
    Writeln('Run: rabbitmq-plugins enable rabbitmq_management');
    Writeln;

    // 1. Publish a sample message
    PublishViaRabbitMQREST('Hello from Delphi REST API! Timestamp: ' + DateTimeToStr(Now));
    PublishViaRabbitMQREST('Test Message #' + IntToStr(Random(1000)));
    Writeln;

    // 2. Fetch a message from the queue
    // Note: Ensure your queue is bound to 'amq.direct' with 'test-routing-key'
    FetchViaRabbitMQREST;
    Writeln;

    Writeln('Demo completed successfully.');
    Writeln('Press [Enter] to exit...');
    Readln;

  except
    on E: EIdHTTPProtocolException do
    begin
      Writeln('HTTP Protocol Error: ' + E.Message);
      Writeln('Code: ' + IntToStr(E.ErrorCode));
      Writeln('Check if your Queue/Exchange exists and credentials are correct.');
      Readln;
    end;
    on E: Exception do
    begin
      Writeln('Error: ' + E.ClassName + ': ' + E.Message);
      Readln;
    end;
  end;
end.
