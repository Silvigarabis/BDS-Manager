exec-cmd(){
  if [[ ! $EXEC ]]; then
    coproc bash
    EXEC=(
      "${COPROC_PID}"
      "${COPROC[0]}"
      "${COPROC[1]}"
    )
    {
      coproc {
        cat <&${EXEC[1]} >&5
      }
    } 5>&1
    exec-cmd "$@"
  elif ! ps ${EXEC[0]} &>/dev/null
  then
    unset EXEC
    exec-cmd "$@"
  else
    echo "$@">&${EXEC[2]}
  fi
}

while read -er
do
exec-cmd "$REPLY"
done
