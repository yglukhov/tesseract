
type
  BaseAPI* = ptr object
  EngineMode* {.size: sizeof(cint).} = enum
    OEM_TESSERACT_ONLY
    OEM_LSTM_ONLY
    OEM_TESSERACT_LSTM_COMBINED
    OEM_DEFAULT
  ResultIterator* = ptr object
  PageIteratorLevel* {.size: sizeof(cint).} = enum
    RIL_BLOCK
    RIL_PARA
    RIL_TEXTLINE
    RIL_WORD
    RIL_SYMBOL

{.pragma: importes, importc, dynlib: "libtesseract.so".}

proc newBaseAPI*(): BaseAPI {.importes, importc: "TessBaseAPICreate".}
proc delete*(a: BaseAPI) {.importes, importc: "TessBaseAPIDelete".}

proc init*(a: BaseAPI, datapath, language: cstring,
                             mode: EngineMode,
                             configs: pointer, configs_size: cint, vars_vec, vars_values: pointer,
                             vars_vec_size: csize_t,
                             set_only_non_debug_params: cint) {.importes, importc: "TessBaseAPIInit4".}

proc init*(a: BaseAPI, datapath: cstring = nil, language: cstring = nil, mode: EngineMode = OEM_DEFAULT, params: openarray[(string, string)]) =
  var ks = newSeqOfCap[cstring](params.len)
  var vs = newSeqOfCap[cstring](params.len)
  for (k, v) in params:
    ks.add(k)
    vs.add(v)
  let pks = if ks.len == 0: nil else: addr ks[0]
  let pvs = if vs.len == 0: nil else: addr vs[0]
  a.init(datapath, language, mode, pointer(nil), 0, pks, pvs, params.len.csize_t, 0)

proc setImage*(a: BaseAPI, data: pointer, width, height, bytesPerPixel, bytesPerLine: cint) {.importes, importc: "TessBaseAPISetImage"}
proc recognize*(a: BaseAPI, monitor: pointer): cint {.importes, importc: "TessBaseAPIRecognize".}
proc c_free(p: pointer) {.importc: "free".}
proc getUTF8TextAux(a: BaseAPI): cstring {.importes, importc: "TessBaseAPIGetUTF8Text".}
proc getUtf8Text*(a: BaseAPI): string =
  let s = a.getUTF8TextAux()
  result = $s
  c_free(s)

proc setRectangle*(a: BaseAPI, l, t, w, h: cint) {.importes, importc: "TessBaseAPISetRectangle".}
proc setRectangle*(a: BaseAPI, r: tuple[l, t, w, h: int]) =
  setRectangle(a, r.l.cint, r.t.cint, r.w.cint, r.h.cint)

proc getIterator*(a: BaseAPI): ResultIterator {.importes, importc: "TessBaseAPIGetIterator".}

proc delete*(r: ResultIterator) {.importes, importc: "TessResultIteratorDelete".}
proc next*(r: ResultIterator, l: PageIteratorLevel): cint {.importes, importc: "TessResultIteratorNext".}

proc getUTF8TextAux(r: ResultIterator, l: PageIteratorLevel): cstring {.importes, importc: "TessResultIteratorGetUTF8Text".}
proc getUtf8Text*(r: ResultIterator, l: PageIteratorLevel): string =
  let s = r.getUTF8TextAux(l)
  result = $s
  c_free(s)

proc boundingBox*(i: ResultIterator, lv: PageIteratorLevel, l, t, r, b: ptr cint) {.importes, importc: "TessPageIteratorBoundingBox".}

proc boundingBox*(i: ResultIterator, lv: PageIteratorLevel): tuple[l, t, r, b: int] =
  var l, t, r, b: cint
  i.boundingBox(lv, addr l, addr t, addr r, addr b)
  (l.int, t.int, r.int, b.int)
