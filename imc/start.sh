if [ -e ./bash ]; then
  rm bash
  exec bash --rcfile bash.rc
else
. ./imc.sh
fi
