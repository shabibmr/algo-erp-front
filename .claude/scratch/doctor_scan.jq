. as $all
| ( [ $all[] | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | {key: .id, value: {name: .name, input: .input}} ] | from_entries ) as $toolmap
| (
    # 1. tool_use rows (all tool calls, for usage-window signal)
    ( $all[] | select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
      | if .name == "Bash" then "TOOL\tBash\t" + ((.input.command // "") | tostring | .[0:80] | gsub("\t";" ") | gsub("\n";" "))
        elif .name == "Skill" then "TOOL\tSkill\t" + (.input.skill // "" | tostring)
        else "TOOL\t" + .name + "\t"
        end
    ),
    # 2. slash command invocations from user text content
    ( $all[] | select(.type=="user") | .message.content
      | (if type=="string" then . else ( [ .[]? | select(.type=="text") | .text ] | join(" ") ) end) as $txt
      | ($txt | scan("<command-name>([^<]*)</command-name>")[]?)
      | "CMD\t" + .
    ),
    # 3. hook attachment rows
    ( $all[] | select(.type=="attachment" and (.attachment.type|test("^hook_")))
      | .attachment as $a
      | "HOOK\t" + ($a.hookEvent // "?") + "\t" + ($a.hookName // "?") + "\t" + (($a.durationMs // -1)|tostring) + "\t" + ($a.type) + "\t" + (($a.timedOut // false)|tostring)
    ),
    # 4. denial rows (CLI-stamped toolDenialKind)
    ( $all[] | select(.type=="user" and has("toolDenialKind"))
      | . as $d
      | ($d.message.content[]? | select(.type=="tool_result") | .tool_use_id) as $tid
      | ($toolmap[$tid] // {name:"UNKNOWN", input:{}}) as $t
      | "DENY\t" + $d.toolDenialKind + "\t" + $t.name + "\t" + (
          if $t.name == "Bash" then ($t.input.command // "" | tostring | .[0:100] | gsub("\t";" ") | gsub("\n";" "))
          else ($t.input | tostring | .[0:100])
          end
        )
    ),
    # 5. fallback denial rows (is_error text match) - excluded for mcp__* per instructions
    ( $all[] | select(.type=="user" and (has("toolDenialKind")|not))
      | . as $d
      | ($d.message.content[]? | select(.type=="tool_result" and .is_error==true)) as $tr
      | ($tr.content | if type=="string" then . else ([.[]? | .text?] | join(" ")) end) as $txt
      | select($txt != null and (($txt|test("doesn't want to proceed with this tool use")) or ($txt|test("^Permission to use")) or ($txt|test("^Permission for this"))))
      | ($tr.tool_use_id) as $tid
      | ($toolmap[$tid] // {name:"UNKNOWN", input:{}}) as $t
      | select($t.name != null and ($t.name | test("^mcp__") | not))
      | "DENYFALLBACK\t" + $t.name + "\t" + (
          if $t.name == "Bash" then ($t.input.command // "" | tostring | .[0:100] | gsub("\t";" ") | gsub("\n";" "))
          else ($t.input | tostring | .[0:100])
          end
        )
    )
  )
