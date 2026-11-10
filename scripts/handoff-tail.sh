#!/usr/bin/env bash
# Handoff tail: bir Claude Code session transcript'ini (.jsonl) yeni bir session'a
# devredilecek kadar sadeleştirir. Araç sonuçları atılır, ardışık araç çağrıları tek
# satıra toplanır, uzun agent metinleri kısaltılır.
#
# Kullanım:
#   handoff-tail.sh [-K] [session.jsonl]
#     -K       son K kullanıcı promptu + öncesindeki son özet (varsayılan -1).
#              İş tamamlandıysa K bir azaltılır: -1 = sadece son özet.
#     dosya    verilmezse bu klasörün projesindeki en yeni session (PREV=n ile n. önceki)
#   handoff-tail.sh --list    bu projenin son 10 session dosyası
#
# Ortam değişkenleri:
#   MAXCHARS=600   ara agent mesajlarının kısaltma sınırı
#   FULL=1         iş tamamlanmış olsa da K'yı azaltma
#   PREV=1         dosya verilmezse kaçıncı en yeni session
#
# Gereksinim: jq

set -euo pipefail

PROJ_DIR="$HOME/.claude/projects/$(pwd | sed 's/[^A-Za-z0-9]/-/g')"

if [[ "${1:-}" == "--list" ]]; then
  ls -lt "$PROJ_DIR"/*.jsonl 2>/dev/null | head -10 || echo "Bulunamadı: $PROJ_DIR"
  exit 0
fi

ARG="${1:--1}"
[[ "$ARG" =~ ^-[0-9]+$ ]] || { echo "İlk parametre -1, -2 ... olmalı" >&2; exit 1; }
K="${ARG#-}"
FILE="${2:-}"
MAXCHARS="${MAXCHARS:-600}"
FULL="${FULL:-0}"

if [[ -z "$FILE" ]]; then
  PREV="${PREV:-1}"
  FILE="$(ls -t "$PROJ_DIR"/*.jsonl 2>/dev/null | sed -n "$((PREV + 1))p")"
  [[ -z "$FILE" ]] && { echo "Session dosyası bulunamadı: $PROJ_DIR (dosya yolunu 2. parametre olarak verebilirsin)" >&2; exit 1; }
fi

read -r -d '' PROG <<'JQ' || true
def txt:
  (if (.message.content | type) == "string" then .message.content
   else ([ .message.content[]? | select(.type == "text") | .text ] | join("\n")) end)
  | gsub("<system-reminder>[\\s\\S]*?</system-reminder>"; "")
  | gsub("^\\s+|\\s+$"; "");
def tools:
  if (.message.content | type) == "array"
  then [ .message.content[]? | select(.type == "tool_use") | .name ] else [] end;
def isres:
  (.message.content | type) == "array" and any(.message.content[]?; .type == "tool_result");
def cut($n): if length > $n then .[0:$n] + " …[kısaltıldı]" else . end;
def toolline($t):
  "   [araçlar: "
  + ($t | group_by(.) | map(.[0] + (if length > 1 then "×" + (length | tostring) else "" end)) | join(", "))
  + "]";

# 1) Transcript'i sade kayıtlara indir
[ .[]
  | select(.type == "user" or .type == "assistant")
  | select(.isSidechain != true and .isMeta != true)
  | select(.isApiErrorMessage != true and .message.model? != "<synthetic>")   # limit/hata mesajları özet değildir
  | txt as $t
  | if .isCompactSummary == true then {k: "summary", t: $t}
    elif .type == "user" then
      if isres then {k: "result"}
      elif ($t | length) == 0 or ($t | test("^(<command-|<local-command|\\[Request interrupted)")) then empty
      else {k: "prompt", t: $t} end
    else
      tools as $tl
      | if ($t | length) == 0 and ($tl | length) == 0 then empty
        else {k: "agent", t: $t, tools: $tl} end
    end
] as $a0
# Bir promptan hemen önceki araçsız agent mesajı = o turun özeti
| [ range(0; $a0 | length) as $i | $a0[$i]
    + (if $a0[$i].k == "agent" and ($a0[$i].tools | length) == 0
         and ($a0[$i + 1].k? // null) == "prompt" then {turnend: true} else {} end) ] as $a

| if ($a | length) == 0 then "Transcript boş." else

  # 2) İş tamamlandı mı? Son kayıt: araç çağırmayan, metin içeren agent mesajı
  ($a[-1] | .k == "agent" and (.tools | length) == 0 and (.t | length) > 0) as $done
  | (if $done and ($full != "1") then $K - 1 else $K end) as $k
  | [ range(0; $a | length) | select($a[.].k == "prompt") ] as $P

  | (if $k == 0 then
      [ $a[-1] + {final: true} ]
    else
      (if ($P | length) == 0 then 0
       elif $k > ($P | length) then $P[0]
       else $P[($P | length) - $k] end) as $start
      | ([ range(0; $start) | select($a[.].k == "summary" or ($a[.].k == "agent" and ($a[.].t | length) > 0)) ] | last) as $s
      | (if $s != null then [ $a[$s] + {prev: true} ] else [] end)
        + ($a[$start:] | to_entries | map(.value + (if $done and .key == ($a[$start:] | length) - 1 then {final: true} else {} end)))
    end) as $items

  # 3) Biçimlendir: ardışık araç-çağrısı adımlarını tek satıra topla
  | ($items | reduce .[] as $r ({out: [], pend: []};
      if $r.k == "result" then .
      elif $r.k == "agent" and ($r.t | length) == 0 then .pend += $r.tools
      else
        (if (.pend | length) > 0 then .out += [toolline(.pend)] | .pend = [] else . end)
        | .out += [
            if $r.prev then
              (if $r.k == "summary" then "## ÖNCEKİ ÖZET (compact)" else "## ÖNCEKİ ÖZET" end) + "\n" + $r.t
            elif $r.final then "## SON ÖZET (iş tamamlandı)\n" + $r.t
            elif $r.k == "summary" then "## COMPACT ÖZETİ\n" + $r.t
            elif $r.turnend then "## TUR ÖZETİ\n" + $r.t
            elif $r.k == "prompt" then "## KULLANICI\n" + $r.t
            else "### agent\n" + ($r.t | cut($max))
              + (if ($r.tools | length) > 0 then "\n" + toolline($r.tools) else "" end)
            end ]
      end)
    | if (.pend | length) > 0 then .out += [toolline(.pend)] else . end
    | .out) as $lines

  | ( "# Durum: " + (if $done then "TAMAMLANDI" else "YARIM KALDI (son adım bir araç çağrısı ya da yanıtsız prompt)" end)
      + " | istenen: -" + ($K | tostring) + " | uygulanan pencere: "
      + (if $k == 0 then "sadece son özet" else "son " + ($k | tostring) + " prompt + öncesindeki özet" end)
    ),
    "",
    ($lines | join("\n\n"))
  end
JQ

echo "# Kaynak: $FILE"
jq -s -r --argjson K "$K" --argjson max "$MAXCHARS" --arg full "$FULL" "$PROG" "$FILE"
