import private/internals
import http/private/wit/[spin_http, wasi_outbound_http]
import http/private/[types, utils]
import std/[tables, uri]

export types

template httpComponent*(handler: proc (req: Request): Response) =
  proc handleHttpRequest(req: ptr spin_http_request_t,
                        res: ptr spin_http_response_t)
                        {.exportc: "spin_http_handle_http_request".} =
    defer: spinHttpRequestFree(req)
    wasm_call_ctors()
    let request = fromSpin(req[])
    let response = handler(request)
    res.status = response.status
    res.headers = response.headers.toSpin
    res.body = response.body.toSpin

proc request*(req: Request): (Response, WasiCode) =
  var
    spinReq = req.toWasi
    spinRes = newWasiResponse()
  defer:
    wasiOutboundHttpRequestFree(spinReq)
    wasiOutboundHttpResponseFree(spinRes)
  let wasiCode = wasiOutboundHttpRequest(spinReq, spinRes)
  (fromSpin(spinRes[]), wasiCode.WasiCode)

proc get*(uri: Uri, headers = newTable[string, string]()): (Response, WasiCode) =
  request(Request(`method`: HttpGet, uri: uri, headers: headers))

proc get*(uri: string, headers = newTable[string, string]()): (Response, WasiCode) =
  get(parseUri(uri), headers)