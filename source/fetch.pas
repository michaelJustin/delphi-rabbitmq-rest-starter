uses
  System.SysUtils,
  System.Classes,
  IdHTTP,
  IdSSLOpenSSL;

/// <summary>
/// Fetches a single message from a RabbitMQ queue using the HTTP REST Management API.
/// Note: This is a synchronous Request/Response call (Polling).
/// </summary>
procedure FetchViaRabbitMQREST(const AHost, AUsername, APassword, AVhost, AQueue: string);
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

    // 3. Construct the JSON Request Payload
    // RabbitMQ requires a POST request to specify how to read and acknowledge the message
    RequestBody.Add('{');
    RequestBody.Add('  "vhost": "' + AVhost + '",');
    RequestBody.Add('  "name": "' + AQueue + '",');
    RequestBody.Add('  "count": "1",');                // Fetch 1 message
    RequestBody.Add('  "ackmode": "ack_requeue_false",'); // Automatically acknowledge and remove from queue
    RequestBody.Add('  "encoding": "auto"');
    RequestBody.Add('{');

    // 4. Construct the API Endpoint URL
    // Standard management port is 15672 (HTTP) or 15671 (HTTPS)
    TargetURL := Format('http://%s:15672/api/queues/%s/%s/get', [AHost, AVhost, AQueue]);

    try
      // 5. Execute the Synchronous HTTP POST request
      IdHTTP.Post(TargetURL, RequestBody, ResponseStream);
      
      // If the queue is empty, RabbitMQ returns an empty array: []
      // If a message exists, it returns a JSON array containing the payload and properties
      if ResponseStream.DataString = '[]' then
        Writeln('Queue is empty. No message returned.')
      else
        Writeln('Server Response: ' + ResponseStream.DataString);
        
    except
      on E: EIdHTTPProtocolException do
      begin
        Writeln('HTTP Error (' + IntToStr(E.ErrorCode) + '): ' + E.ErrorMessage);
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
