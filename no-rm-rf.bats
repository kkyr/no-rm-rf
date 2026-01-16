#!/usr/bin/env bats

# Helper to run the script with a command
json_escape() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  printf '%s' "$s"
}

run_hook() {
  local cmd="$1"
  local json
  json="{\"tool_input\":{\"command\":\"$(json_escape "$cmd")\"}}"
  run bash -c 'printf %s "$1" | ./no-rm-rf.sh' -- "$json"
}

# --- Blocked commands (exit 2) ---

@test "blocks rm" {
  run_hook "rm file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks rm -rf" {
  run_hook "rm -rf /tmp/test"
  [ "$status" -eq 2 ]
}

@test "blocks shred" {
  run_hook "shred file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks unlink" {
  run_hook "unlink file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks find -delete" {
  run_hook "find . -name '*.tmp' -delete"
  [ "$status" -eq 2 ]
}

@test "blocks find -exec rm" {
  run_hook "find . -exec rm {} \\;"
  [ "$status" -eq 2 ]
}

@test "blocks sudo rm" {
  run_hook "sudo rm file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks xargs rm" {
  run_hook "echo file.txt | xargs rm"
  [ "$status" -eq 2 ]
}

@test "blocks /bin/rm" {
  run_hook "/bin/rm file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks /usr/bin/rm" {
  run_hook "/usr/bin/rm file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks backslash rm" {
  run_hook "\\rm file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks command rm" {
  run_hook "command rm file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks env rm" {
  run_hook "env rm file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks rm after &&" {
  run_hook "ls && rm file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks rm after ||" {
  run_hook "ls || rm file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks rm after ;" {
  run_hook "ls; rm file.txt"
  [ "$status" -eq 2 ]
}

@test "blocks rm after |" {
  run_hook "echo file | rm"
  [ "$status" -eq 2 ]
}

@test "blocks bash -c rm" {
  run_hook "bash -c 'rm file.txt'"
  [ "$status" -eq 2 ]
}

@test "blocks sh -c rm" {
  run_hook "sh -c 'rm file.txt'"
  [ "$status" -eq 2 ]
}

# --- Allowed commands (exit 0) ---

@test "allows git rm" {
  run_hook "git rm file.txt"
  [ "$status" -eq 0 ]
}

@test "allows git rm --cached" {
  run_hook "git rm --cached file.txt"
  [ "$status" -eq 0 ]
}

@test "allows rm in double quotes" {
  run_hook 'echo "rm file.txt"'
  [ "$status" -eq 0 ]
}

@test "allows rm in single quotes" {
  run_hook "echo 'rm file.txt'"
  [ "$status" -eq 0 ]
}

@test "allows ls" {
  run_hook "ls -la"
  [ "$status" -eq 0 ]
}

@test "allows cat" {
  run_hook "cat file.txt"
  [ "$status" -eq 0 ]
}

@test "allows empty command" {
  run_hook ""
  [ "$status" -eq 0 ]
}

@test "allows trash command" {
  run_hook "trash file.txt"
  [ "$status" -eq 0 ]
}

@test "allows invalid json" {
  run bash -c 'printf %s "{not json" | ./no-rm-rf.sh'
  [ "$status" -eq 0 ]
}
