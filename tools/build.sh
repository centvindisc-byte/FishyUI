#!/usr/bin/env bash
# Bundles src/*.lua (in filename order) into the single-file Library.lua that loadstring() consumes,
# then writes build/FishyUI_test.lua (library + examples/demo.lua) for pasting straight into an executor.
set -euo pipefail
cd "$(dirname "$0")/.."

out=Library.lua
{
  echo "-- FishyUI | generated from src/ by tools/build.sh. Edit the files in src/, not this one."
  for f in src/*.lua; do
    echo ""
    echo "-- ===== ${f#src/} ====="
    cat "$f"
  done
} > "$out"

# Globals the library is entitled to use: the Luau standard library, Roblox's datatypes and singletons,
# and the executor surface. luau-analyze has no type definitions for these, so it reports every one of
# them as unknown; they are filtered out so that what remains is signal.
ALLOWED_GLOBALS=" _G _VERSION assert bit32 buffer collectgarbage coroutine debug delay error gcinfo
getmetatable ipairs loadstring math newproxy next os pairs pcall print rawequal rawget rawlen rawset
require select setmetatable spawn string table task tick time tonumber tostring type typeof unpack
utf8 wait warn xpcall
Axes BrickColor CFrame Color3 ColorSequence ColorSequenceKeypoint DateTime Enum Faces Font Instance
NumberRange NumberSequence NumberSequenceKeypoint OverlapParams PathWaypoint PhysicalProperties Random
Ray RaycastParams Rect Region3 Region3int16 TweenInfo UDim UDim2 Vector2 Vector2int16 Vector3
Vector3int16 game plugin script shared workspace
cloneref delfile delfolder getconnections getgenv gethui hookfunction http_request identifyexecutor
isfile isfolder listfiles makefolder queue_on_teleport readfile request setclipboard writefile "

check() {
  command -v luau-analyze >/dev/null || return 0
  # The list above is wrapped across lines for legibility; collapse it so every name is
  # space-delimited, otherwise a name sitting at a line break never matches the case pattern.
  local allowed=" $(echo $ALLOWED_GLOBALS) "
  local report syntax bad name
  report=$(luau-analyze --formatter=plain "$1" 2>&1 || true)

  syntax=$(echo "$report" | grep "SyntaxError" || true)
  if [ -n "$syntax" ]; then
    echo "$syntax"
    exit 1
  fi

  # Every src/*.lua shares one scope and they are concatenated in filename order, so referencing
  # something defined in a later file compiles to a nil global and only fails at runtime, on the
  # frame the user happens to touch that control. This catches it at build time instead.
  bad=""
  for name in $(echo "$report" | grep -oE "Unknown global '[^']+'" | sed "s/Unknown global '//;s/'//" | sort -u); do
    case "$allowed" in
      *" $name "*) ;;
      *) bad="$bad $name" ;;
    esac
  done
  if [ -n "$bad" ]; then
    echo "$1: used before it is defined (check src/ file ordering):$bad"
    exit 1
  fi
}

check "$out"
echo "built $out ($(wc -l < "$out") lines)"

mkdir -p build
test_out=build/FishyUI_test.lua
{
  echo "-- FishyUI test build: the full library plus the demo window. Re-executing unloads the previous copy."
  echo "do"
  echo "    local env = (typeof(getgenv) == \"function\" and getgenv()) or _G"
  echo "    local prior = env.Library"
  echo "    if type(prior) == \"table\" and type(prior.Unload) == \"function\" then pcall(prior.Unload, prior) end"
  echo "end"
  echo ""
  echo "local Library = (function()"
  cat "$out"
  echo "end)()"
  echo ""
  cat examples/demo.lua
} > "$test_out"
check "$test_out"
echo "built $test_out ($(wc -l < "$test_out") lines)"
