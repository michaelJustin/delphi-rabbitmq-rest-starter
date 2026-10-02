uses
  System.SysUtils,
  System.Classes,
  IdHTTP,
  IdSSLOpenSSL;

/// <summary>
/// Publishes a message to RabbitMQ using the HTTP REST Management API.
/// Note: Requires the 'rabbitmq_management' plugin enabled on the broker.
/// </summary>
procedure PublishViaRabbitMQREST(const AHost, AUsername, APassword, AVhost, AExchange, ARoutingKey, AMessage: string);
var
  IdHTTP: TIdHTTP;
  SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
  RequestBody: TStringList;
  ResponseStream: TStringStream;
  TargetURL: string;
begin
  IdHTTP := TIdHTTP.Create(nil);
  SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  RequestBody := TStringList.Create;
  ResponseStream := TStringStream.Create;
  try
    // 1. Configure SSL/TLS (Required if using HTTPS port 15671)
    IdHTTP.IOHandler := SSLHandler;
    SSLHandler.SSLOptions.Method := sslvTLSv1_2;

    // 2. Setup Basic Authentication
    IdHTTP.Request.BasicAuthentication := True;
    IdHTTP.Request.Username := AUsername;
    IdHTTP.Request.Password := APassword;
    IdHTTP.Request.ContentType := 'application/json';

    // 3. Construct the RabbitMQ JSON Payload
    // The REST API expects standard JSON configuration for properties and routing
    RequestBody.Add('{');
    RequestBody.Add('  "properties": {},');
    RequestBody.Add('  "routing_key": "' + ARoutingKey + '",');
    RequestBody.Add('  "payload": "' + AMessage + '",');
    RequestBody.Add('  "payload_encoding": "string"');
    RequestBody.Add('}');

    // 4. Construct the API Endpoint URL
    // Standard management port is 15672 (HTTP) or 15671 (HTTPS)
    // Note: Virtual host '/' must be escaped as '%2F'
    TargetURL := Format('http://%s:15672/api/exchanges/%s/%s/publish', [AHost, AVhost, AExchange]);

    try
      // 5. Execute the Synchronous HTTP POST request
      IdHTTP.Post(TargetURL, RequestBody, ResponseStream);
      
      // Output server response (RabbitMQ returns json like {"routed":true})
      Writeln('Server Response: ' + ResponseStream.DataString);
    except
      on E: EIdHTTPProtocolException do
      begin
        Writeln('HTTP Error (' + IntToStr(E.ErrorCode) + '): ' + E.ErrorMessage);
        Writeln('Details: ' + E.ErrorMessage);
      end;
      on E: Exception do
      begin
        Writeln('Connection Error: ' + E.Message);
      end;
    end;

  finally
    ResponseStream.Free;
    RequestBody.Free;
    SSLHandler.Free;
    IdHTTP.Free;
  end;
end;
