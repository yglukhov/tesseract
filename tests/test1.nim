# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest, osproc, os, parseutils
# import nimPNG
import pixie

const tmpImageName = "/tmp/_trainer_coc"

# const tmpScreenshot = tmpImageName & "1.png"
const tmpScreenshot = "/home/y/proj/adbclient/5.png"
const tmpFiltered = tmpImageName & "2.png"

type
  Rect = tuple[l, t, r, b: int]
  Coord = int

proc x*(r: Rect): Coord = r.l
proc y*(r: Rect): Coord = r.t
proc width*(r: Rect): Coord = r.r
proc height*(r: Rect): Coord = r.b

proc minX*(r: Rect): Coord = r.x
proc maxX*(r: Rect): Coord = r.x + r.width
proc minY*(r: Rect): Coord = r.y
proc maxY*(r: Rect): Coord = r.y + r.height

proc intersects(r, c: Rect): bool =
  if r.minX < c.maxX and c.minX < r.maxX and r.minY < c.maxY and c.minY < r.maxY:
    result = true

const goldRect = (169, 134, 304, 42)
const elixRect = (169, 190, 304, 42)
const darkRect = (169, 250, 304, 42)

proc isEnemyGold(r: Rect): bool =
  r.l > 95 and
    r.r < 270 and
    r.t > 110 and
    r.b < 150

proc isEnemyElix(r: Rect): bool =
  r.l > 95 and
    r.r < 270 and
    r.t > 160 and
    r.b < 195
  # r.intersects((140, 168, 248, 187))

proc isEnemyDark(r: Rect): bool =
  r.l > 95 and
    r.r < 270 and
    r.t > 205 and
    r.b < 245
  # r.intersects((140, 215, 214, 235))

proc captureScreenshot(a: string) =
  discard execCmd("adb exec-out screencap -p > \"" & a & "\"")

proc filterImage(a: string) =
  # discard execCmd("ffmpeg -loglevel error -y -i \"" & a & "\" -vf \"negate, eq=contrast=3:brightness=1.0:saturation=0, scale=1920:trunc(ow/a/2)*2\" " & tmpFiltered)
  discard execCmd("ffmpeg -loglevel error -y -i \"" & a & "\" -vf \"negate, eq=contrast=3:brightness=1.0:saturation=0\" " & tmpFiltered)

import tesseract

proc getNumberInRect(a: BaseAPI, r: tuple[l, t, w, h: int]): int =
  a.setRectangle(r)
  let s = a.getUtf8Text()
  if parseInt(s, result) <= 0:
    result = -1

test "can add":
  let a = newBaseAPI()
  a.init(language = "eng", params = {"tessedit_char_whitelist": "0123456789"})
  if true:
    echo "making screenshot"
    # captureScreenshot(tmpScreenshot)
    filterImage(tmpScreenshot)
    let i = readImage(tmpFiltered)
    echo "png loaded"
    a.setImage(addr i.data[0], i.width.cint, i.height.cint, 4, cint(i.width * 4))

    # echo "gold: ", a.getNumberInRect(goldRect)
    # let gold = block:
    # a.setRectangle(goldRect)
    # echo "TEXT: ", a.getUtf8Text()
    echo "GOLD: ", a.getNumberInRect(goldRect)
    echo "ELIX: ", a.getNumberInRect(elixRect)
    echo "DARK: ", a.getNumberInRect(darkRect)

  echo "done"
  # a.setRectangle(163, 134, 266, 40)
  a.delete()
