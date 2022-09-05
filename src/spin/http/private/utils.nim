import wit/[spin_http, wasi_outbound_http], types
import spin/private/utils
import std/[tables, options]
from std/httpclient import HttpMethod

const httpMethods = {
  SPIN_HTTP_METHOD_GET: HttpGet,
  SPIN_HTTP_METHOD_POST: HttpPost,
  SPIN_HTTP_METHOD_PUT: HttpPut,
  SPIN_HTTP_METHOD_DELETE: HttpDelete,
  SPIN_HTTP_METHOD_PATCH: HttpPatch,
  SPIN_HTTP_METHOD_HEAD: HttpHead,
  SPIN_HTTP_METHOD_OPTIONS: HttpOptions
}.toTable

proc nth[T](base: ptr T, n: SomeInteger): ptr T =
  let size = sizeof T
  let header = addr(cast[ptr UncheckedArray[byte]](base)[n.int * size])
  cast[ptr T](header)

proc fromSpin(headers: spin_http_headers_t): HttpHeaders =
  result = newTable[string, string]()
  for i in 0..<headers.len:
    let header = headers.ptr.nth(i)
    result[$header.f0.ptr] = $header.f1.ptr

proc toSpin(headers: HttpHeaders): spin_http_headers_t =
  result.ptr = nalloc(headers.len, spin_http_tuple2_string_string_t)
  for key, val in headers:
    result.len += 1
    let header = result.ptr.nth(result.len - 1)
    spinHttpStringSet(addr header.f0, newUnmanagedStr(key))
    spinHttpStringSet(addr header.f1, newUnmanagedStr(val))

proc toSpin*(headers: Option[HttpHeaders]): spin_http_option_headers_t =
  if headers.isSome:
    result.isSome = true
    result.val = headers.get.toSpin

proc fromSpin(params: spin_http_params_t): HttpParams =
  result = newTable[string, string]()
  for i in 0..<params.len:
    let param = params.ptr.nth(i)
    result[$param.f0.ptr] = $param.f1.ptr

proc fromSpin(body: spin_http_option_body_t): Option[string] =
  if body.isSome:
    let len = body.val.len
    if len > 0:
      let str = newString(len)
      copyMem(unsafeAddr str[0], body.val.ptr, len)
      result = some(str)

proc toSpin*(body: Option[string]): spin_http_option_body_t =
  if body.isSome:
    result.isSome = true
    var dataPtr = nalloc(body.get.len, byte)
    copyMem(dataPtr, unsafeAddr body.get[0], body.get.len)
    result.val = spin_http_body_t(
      `ptr`: dataPtr,
      len: body.get.len.uint
    )

proc fromSpin*(request: spin_http_request_t): Request =
  Request(
    `method`: httpMethods[request.method],
    uri: $request.uri.ptr,
    headers: request.headers.fromSpin,
    params: request.params.fromSpin,
    body: request.body.fromSpin
  )

const outboundHttpMethods = {
  HttpGet: WASI_OUTBOUND_HTTP_METHOD_GET,
  HttpPost: WASI_OUTBOUND_HTTP_METHOD_POST,
  HttpPut: WASI_OUTBOUND_HTTP_METHOD_PUT,
  HttpDelete: WASI_OUTBOUND_HTTP_METHOD_DELETE,
  HttpPatch: WASI_OUTBOUND_HTTP_METHOD_PATCH,
  HttpHead: WASI_OUTBOUND_HTTP_METHOD_HEAD,
  HttpOptions: WASI_OUTBOUND_HTTP_METHOD_OPTIONS
}.toTable

# TODO
proc fromWasi(headers: wasi_outbound_http_option_headers_t): Option[HttpHeaders] =
  discard

proc toWasi(headers: HttpHeaders): wasi_outbound_http_headers_t =
  discard
  result.ptr = nalloc(headers.len, wasi_outbound_http_tuple2_string_string_t)
  for key, val in headers:
    result.len += 1
    let header = result.ptr.nth(result.len - 1)
    wasiOutboundHttpStringSet(addr header.f0, newUnmanagedStr(key))
    wasiOutboundHttpStringSet(addr header.f1, newUnmanagedStr(val))

proc fromWasi(body: wasi_outbound_http_option_body_t): Option[string] =
  discard

# TODO
proc toWasi*(req: Request): ptr wasi_outbound_http_request_t  =
  result = nalloc(1, wasi_outbound_http_request_t)
  result.method = outboundHttpMethods[req.method].uint8
  wasiOutboundHttpStringSet(addr result.uri, newUnmanagedStr(req.uri))
  # result.headers
  # result.params
  # result.body

# TODO
proc newWasiResponse*(): ptr wasi_outbound_http_response_t =
  nalloc(1, wasi_outbound_http_response_t)

# TODO
proc fromSpin*(res: wasi_outbound_http_response_t): Response =
  Response(
    status: res.status,
    headers: res.headers.fromWasi,
    body: res.body.fromWasi
  )
