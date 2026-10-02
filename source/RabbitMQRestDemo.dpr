program RabbitMQRestDemo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  IdHTTP,
  IdSSLOpenSSL;

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
  RequestBody: TStringList;
  ResponseStream: TStringStream;
  TargetURL: string;
begin
  IdHTTP := TIdHTTP.Create(nil);
  RequestBody := TStringList.Create;
  ResponseStream := TStringStream.Create;
  try
    IdHTTP.Request.BasicAuthentication := True;
    IdHTTP.Request.Username := RABBITMQ_USER;
    IdHTTP.Request.Password := RABBITMQ_PASS;
    IdHTTP.Request.ContentType := 'application/json';

    // Construct JSON payload
    RequestBody.Add('{');
    RequestBody.Add('  "properties": {},');
    RequestBody.Add('  "routing_key": "' + ROUTING_KEY + '",');
    RequestBody.Add('  "payload": "' + AMessage + '",');
    RequestBody.Add('  "payload_encoding": "string"');
    RequestBody.Add('}');

    TargetURL := Format('http://%s:%s/api/exchanges/%s/%s/publish', 
      [RABBITMQ_HOST, RABBITMQ_PORT, RABBITMQ_VHOST, TARGET_EXCHANGE]);

    Writeln('Sending message via HTTP POST...');
    IdHTTP.Post(TargetURL, RequestBody, ResponseStream);
    Writeln('Publish Response: ' + ResponseStream.DataString);

  finally
    ResponseStream.Free;
    RequestBody.Free;
    IdHTTP.Free;
  end;
end;

/// <summary>
/// Fetches a single message via the RabbitMQ HTTP REST API
/// </summary>
procedure FetchViaRabbitMQREST;
var
  IdHTTP: TIdHTTP;
  RequestBody: TStringList;
  ResponseStream: TStringStream;
  TargetURL: string;
begin
  IdHTTP := TIdHTTP.Create(nil);
  RequestBody := TStringList.Create;
  ResponseStream := TStringStream.Create;
  try
    IdHTTP.Request.BasicAuthentication := True;
    IdHTTP.Request.Username := RABBITMQ_USER;
    IdHTTP.Request.Password := RABBITMQ_PASS;
    IdHTTP.Request.ContentType := 'application/json';

    // Construct configuration JSON for fetching
    RequestBody.Add('{');
    RequestBody.Add('  "vhost": "/",');
    RequestBody.Add('  "name": "' + TARGET_QUEUE + '",');
    RequestBody.Add('  "count": "1",');
    RequestBody.Add('  "ackmode": "ack_requeue_false",');
    RequestBody.Add('  "encoding": "auto"');
    RequestBody.Add('}');

    TargetURL := Format('http://%s:%s/api/queues/%s/%s/get', 
      [RABBITMQ_HOST, RABBITMQ_PORT, RABBITMQ_VHOST, TARGET_QUEUE]);

    Writeln('Fetching message via HTTP POST...');
    IdHTTP.Post(TargetURL, RequestBody, ResponseStream);
    
    if ResponseStream.DataString = '[]' then
      Writeln('Fetch Response: [Queue is empty]')
    else
      Writeln('Fetch Response: ' + ResponseStream.DataString);

  finally
    ResponseStream.Free;
    RequestBody.Free;
    IdHTTP.Free;
  end;
end;

begin
  try
    Writeln('==================================================');
    Writeln('  Delphi RabbitMQ REST API Starter Project Demo   ');
    Writeln('==================================================');
    Writeln;
    Writeln('Prerequisite: Ensure RabbitMQ Management Plugin is active.');
    Writeln('Run: rabbitmq-plugins enable rabbitmq_management');
    Writeln;

    // 1. Publish a sample message
    PublishViaRabbitMQREST('Hello from Delphi REST API! Timestamp: ' + ColorToHex(0)); // quick random string alternative
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
