#!/usr/bin/env bash
# Query OSV for exact package versions.
#
#   osv-check.sh lodash@4.17.15 hono@4.12.32
#   osv-check.sh --ranges brace-expansion@1.1.18
#
# --ranges also prints each advisory's affected SEMVER ranges, which is how you
# catch the case where pnpm audit reports a flattened "patched: >=X" that has no
# backport to the major you are actually resolving.
set -uo pipefail

show_ranges=0
[[ "${1:-}" == "--ranges" ]] && { show_ranges=1; shift; }

if [[ $# -eq 0 ]]; then
  echo "usage: $(basename "$0") [--ranges] <pkg>@<version>..." >&2
  exit 2
fi

status=0
for spec in "$@"; do
  pkg="${spec%@*}"; ver="${spec##*@}"
  if [[ -z "$pkg" || -z "$ver" || "$pkg" == "$ver" ]]; then
    printf '%-40s %s\n' "$spec" "SKIPPED (expected <pkg>@<version>)"; status=1; continue
  fi

  resp=$(curl -sS -X POST https://api.osv.dev/v1/query \
    -d "{\"package\":{\"name\":\"$pkg\",\"ecosystem\":\"npm\"},\"version\":\"$ver\"}") || {
    printf '%-40s %s\n' "$spec" "QUERY FAILED"; status=1; continue; }

  RANGES=$show_ranges PKG="$pkg" SPEC="$spec" node -e '
    let d=""; process.stdin.on("data",c=>d+=c).on("end",()=>{
      let j; try { j=JSON.parse(d) } catch { console.log(process.env.SPEC+": BAD RESPONSE"); process.exit(1) }
      const vulns=j.vulns||[];
      if(!vulns.length){ console.log(process.env.SPEC.padEnd(40)+"CLEAN"); return }
      console.log(process.env.SPEC.padEnd(40)+vulns.length+" vuln(s)");
      for(const v of vulns){
        const sev=(v.database_specific||{}).severity||"?";
        console.log("    "+v.id+" ["+sev+"] "+(v.summary||"").slice(0,90));
        if(process.env.RANGES==="1")
          for(const a of v.affected||[])
            if(a.package.name===process.env.PKG)
              console.log("        ranges: "+JSON.stringify(a.ranges));
      }
      process.exitCode=1;
    })' <<<"$resp" || status=1
done
exit $status
