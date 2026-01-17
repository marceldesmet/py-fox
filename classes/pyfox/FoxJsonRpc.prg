LOCAL loHttp, lcUrl, lcPayload, lcResponse

* Create HTTP object
loHttp = CreateObject("WinHttp.WinHttpRequest.5.1")

* Odoo JSON-RPC endpoint
lcUrl = "http://localhost:8069/jsonrpc"

* Authentication payload
lcPayload = ;
'{"jsonrpc":"2.0","method":"call","params":{' + ;
'"service":"common","method":"login","args":["Gestion","marcel@jazzjuicers.com","dMsQ84&11"]},' + ;
'"id":1}'

* Send request
loHttp.Open("POST", lcUrl, .F.)
loHttp.SetRequestHeader("Content-Type", "application/json")
loHttp.Send(lcPayload)

* Get response
lcResponse = loHttp.ResponseText
? lcResponse
