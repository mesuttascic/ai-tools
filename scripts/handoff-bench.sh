#!/usr/bin/env bash
# Handoff bench: ~/.claude/projects altındaki en büyük N session'ın toplam token'ını
# handoff-tail.sh -1 / -2 çıktılarıyla karşılaştırır. Markdown tablo + CSV üretir.
#
# Kullanım: ./handoff-bench.sh [N=10]
# Gereksinim: jq, handoff-tail.sh (aynı klasörde, çalıştırılabilir)
#
# Sütunlar:
#   total_tok : son assistant mesajının usage toplamı (input + cache_read + cache_creation)
#               usage yoksa (*) karakter/4 tahmini
#   -1 / -2   : handoff-tail.sh -1 / -2 çıktısının karakter/4 tahmini
#   tasarruf  : 100 * (1 - (-1 token) / total)

set -euo pipefail
N="${1:-10}"
DIR="$(cd "$(dirname "$0")" && pwd)"
TAIL="$DIR/handoff-tail.sh"
ROOT="$HOME/.claude/projects"
[[ -x "$TAIL" ]] || { echo "handoff-tail.sh bulunamadı/çalıştırılamıyor: $TAIL" >&2; exit 1; }

est() { echo $(( $(wc -c | tr -d ' ') / 4 )); }   # stdin karakter/4
words() { wc -w | tr -d ' '; }

OUT_CSV="$DIR/handoff-bench.csv"
echo "klasor,session,baslik,total_tok,min1_tok,min2_tok,min1_kelime,min2_kelime" > "$OUT_CSV"

printf '| Session klasörü | Session başlığı | Total token | -1 token | -2 token | -1 tasarruf |\n'
printf '|---|---|---:|---:|---:|---:|\n'

# Alt-agent (subagents/) dosyalarını hariç tut, boyuta göre en büyük N
find "$ROOT" -maxdepth 2 -name '*.jsonl' -type f -print0 2>/dev/null \
| xargs -0 ls -S 2>/dev/null | head -n "$N" \
| while IFS= read -r f; do
    folder="$(basename "$(dirname "$f")")"
    sid="$(basename "$f" .jsonl | cut -c1-8)"

    title="$(jq -r '
        select(.type=="summary" or .type=="custom-title" or .type=="ai-title")
        | (.summary // .customTitle // .aiTitle // .title // empty)' "$f" 2>/dev/null | tail -1)"
    if [[ -z "$title" ]]; then
      title="$(jq -r 'select(.type=="user" and (.message.content|type)=="string" and (.isMeta!=true))
                      | .message.content' "$f" 2>/dev/null \
               | grep -v '^<' | head -1)"
    fi
    title="$(printf '%s' "$title" | tr '\n|,' '   ' | cut -c1-60)"

    total="$(jq -s '[ .[] | select(.type=="assistant" and .message.usage != null) ] | last
                    | if . == null then empty else .message.usage
                      | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0) end' \
             "$f" 2>/dev/null || true)"
    mark=""
    if [[ -z "$total" || "$total" == "0" ]]; then
      total="$(jq -r '.message.content | if type=="string" then . else (.. | strings) end' "$f" 2>/dev/null | est)"
      mark="*"
    fi

    o1="$("$TAIL" -1 "$f" 2>/dev/null || true)"
    o2="$("$TAIL" -2 "$f" 2>/dev/null || true)"
    t1="$(printf '%s' "$o1" | est)"; w1="$(printf '%s' "$o1" | words)"
    t2="$(printf '%s' "$o2" | est)"; w2="$(printf '%s' "$o2" | words)"
    saving="$(awk -v a="$total" -v b="$t1" 'BEGIN{ if(a>0) printf "%.1f%%", 100*(1-b/a); else print "-" }')"

    printf '| %s | %s (%s) | %s%s | %s | %s | %s |\n' "$folder" "$title" "$sid" "$total" "$mark" "$t1" "$t2" "$saving"
    echo "\"$folder\",$sid,\"$title\",$total,$t1,$t2,$w1,$w2" >> "$OUT_CSV"
  done

echo
echo "(*) usage alanı yok, karakter/4 ile tahmin edildi. -1/-2 sütunları her zaman karakter/4 tahminidir."
echo "CSV: $OUT_CSV"
